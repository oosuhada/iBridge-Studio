import AppKit
@preconcurrency import AVFoundation
import CoreMedia
import Darwin
import Foundation

struct Options {
    var port = 48320
    var fullscreen = false
    var title = "iBridge Receiver"
}

struct RuntimeError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) {
        self.description = description
    }
}

struct SendableSampleBuffer: @unchecked Sendable {
    let value: CMSampleBuffer
}

func usage() {
    print("""
    ibridge-receiver-macos [--port 48320] [--fullscreen] [--title "iBridge Receiver"]

    Receives protocol v0 TCP frames with Annex-B H.264/HEVC payloads and displays
    them with AVSampleBufferDisplayLayer.
    """)
}

func parseOptions(_ args: [String]) throws -> Options {
    var options = Options()
    var index = 1
    while index < args.count {
        let arg = args[index]
        func value() throws -> String {
            guard index + 1 < args.count else {
                throw RuntimeError("\(arg) requires a value")
            }
            index += 1
            return args[index]
        }

        if arg == "--help" || arg == "-h" {
            usage()
            exit(0)
        } else if arg == "--port" {
            options.port = try Int(value()) ?? options.port
        } else if arg.hasPrefix("--port=") {
            options.port = Int(arg.dropFirst("--port=".count)) ?? options.port
        } else if arg == "--fullscreen" {
            options.fullscreen = true
        } else if arg == "--title" {
            options.title = try value()
        } else if arg.hasPrefix("--title=") {
            options.title = String(arg.dropFirst("--title=".count))
        } else {
            throw RuntimeError("unknown argument: \(arg)")
        }
        index += 1
    }
    guard options.port > 0, options.port <= 65535 else {
        throw RuntimeError("--port must be between 1 and 65535")
    }
    return options
}

enum CodecID: UInt8 {
    case h264 = 1
    case hevc = 2
}

struct FrameHeader {
    static let byteCount = 80
    let magic: UInt32
    let version: UInt16
    let headerLen: UInt16
    let sessionID: UInt64
    let frameID: UInt64
    let width: UInt16
    let height: UInt16
    let fps: UInt16
    let codec: UInt8
    let flags: UInt32
    let payloadLen: UInt32
    let droppedBefore: UInt32

    init(_ data: Data) throws {
        guard data.count == Self.byteCount else {
            throw RuntimeError("frame header must be \(Self.byteCount) bytes")
        }
        magic = data.readLE(at: 0, as: UInt32.self)
        version = data.readLE(at: 4, as: UInt16.self)
        headerLen = data.readLE(at: 6, as: UInt16.self)
        sessionID = data.readLE(at: 8, as: UInt64.self)
        frameID = data.readLE(at: 16, as: UInt64.self)
        width = data.readLE(at: 28, as: UInt16.self)
        height = data.readLE(at: 30, as: UInt16.self)
        fps = data.readLE(at: 32, as: UInt16.self)
        codec = data[34]
        flags = data.readLE(at: 36, as: UInt32.self)
        payloadLen = data.readLE(at: 72, as: UInt32.self)
        droppedBefore = data.readLE(at: 76, as: UInt32.self)

        guard magic == 0x4752_4249 else {
            throw RuntimeError("bad frame magic: 0x\(String(magic, radix: 16))")
        }
        guard version == 0, headerLen == Self.byteCount else {
            throw RuntimeError("unsupported frame header version=\(version) header_len=\(headerLen)")
        }
        guard payloadLen > 0 else {
            throw RuntimeError("empty frame payload for frame \(frameID)")
        }
    }

    var isKeyframe: Bool {
        flags & 1 != 0
    }
}

extension Data {
    func readLE<T: FixedWidthInteger>(at offset: Int, as _: T.Type) -> T {
        var value: T = 0
        let _: Void = Swift.withUnsafeMutableBytes(of: &value) { destination in
            copyBytes(to: destination, from: offset..<(offset + MemoryLayout<T>.size))
        }
        return T(littleEndian: value)
    }
}

struct AnnexBNALUnit {
    let data: Data
}

func annexBNALUnits(from payload: Data) -> [AnnexBNALUnit] {
    let bytes = [UInt8](payload)
    var starts: [(offset: Int, length: Int)] = []
    var index = 0
    while index + 3 < bytes.count {
        if bytes[index] == 0, bytes[index + 1] == 0, bytes[index + 2] == 1 {
            starts.append((index, 3))
            index += 3
        } else if index + 4 < bytes.count,
                  bytes[index] == 0, bytes[index + 1] == 0,
                  bytes[index + 2] == 0, bytes[index + 3] == 1 {
            starts.append((index, 4))
            index += 4
        } else {
            index += 1
        }
    }

    var units: [AnnexBNALUnit] = []
    for startIndex in starts.indices {
        let start = starts[startIndex].offset + starts[startIndex].length
        let end = startIndex + 1 < starts.count ? starts[startIndex + 1].offset : bytes.count
        if end > start {
            units.append(AnnexBNALUnit(data: payload.subdata(in: start..<end)))
        }
    }
    return units
}

func h264NALType(_ data: Data) -> UInt8 {
    guard let first = data.first else { return 0 }
    return first & 0x1f
}

func hevcNALType(_ data: Data) -> UInt8 {
    guard let first = data.first else { return 0 }
    return (first >> 1) & 0x3f
}

final class FormatDescriptionBuilder {
    private var h264SPS: Data?
    private var h264PPS: Data?
    private var hevcVPS: Data?
    private var hevcSPS: Data?
    private var hevcPPS: Data?
    private var currentFormat: CMVideoFormatDescription?

    func update(codec: UInt8, units: [AnnexBNALUnit]) throws -> CMVideoFormatDescription? {
        if codec == CodecID.h264.rawValue {
            for unit in units {
                switch h264NALType(unit.data) {
                case 7: h264SPS = unit.data
                case 8: h264PPS = unit.data
                default: break
                }
            }
            if let sps = h264SPS, let pps = h264PPS {
                currentFormat = try makeH264FormatDescription(sps: sps, pps: pps)
            }
        } else if codec == CodecID.hevc.rawValue {
            for unit in units {
                switch hevcNALType(unit.data) {
                case 32: hevcVPS = unit.data
                case 33: hevcSPS = unit.data
                case 34: hevcPPS = unit.data
                default: break
                }
            }
            if let vps = hevcVPS, let sps = hevcSPS, let pps = hevcPPS {
                currentFormat = try makeHEVCFormatDescription(vps: vps, sps: sps, pps: pps)
            }
        } else {
            throw RuntimeError("unsupported codec id \(codec)")
        }
        return currentFormat
    }
}

func makeH264FormatDescription(sps: Data, pps: Data) throws -> CMVideoFormatDescription {
    var formatDescription: CMVideoFormatDescription?
    let status = sps.withUnsafeBytes { spsBytes in
        pps.withUnsafeBytes { ppsBytes in
            var pointers: [UnsafePointer<UInt8>] = [
                spsBytes.bindMemory(to: UInt8.self).baseAddress!,
                ppsBytes.bindMemory(to: UInt8.self).baseAddress!
            ]
            var sizes = [sps.count, pps.count]
            return CMVideoFormatDescriptionCreateFromH264ParameterSets(
                allocator: kCFAllocatorDefault,
                parameterSetCount: 2,
                parameterSetPointers: &pointers,
                parameterSetSizes: &sizes,
                nalUnitHeaderLength: 4,
                formatDescriptionOut: &formatDescription
            )
        }
    }
    guard status == noErr, let formatDescription else {
        throw RuntimeError("CMVideoFormatDescriptionCreateFromH264ParameterSets failed: \(status)")
    }
    return formatDescription
}

func makeHEVCFormatDescription(vps: Data, sps: Data, pps: Data) throws -> CMVideoFormatDescription {
    var formatDescription: CMVideoFormatDescription?
    let status = vps.withUnsafeBytes { vpsBytes in
        sps.withUnsafeBytes { spsBytes in
            pps.withUnsafeBytes { ppsBytes in
                var pointers: [UnsafePointer<UInt8>] = [
                    vpsBytes.bindMemory(to: UInt8.self).baseAddress!,
                    spsBytes.bindMemory(to: UInt8.self).baseAddress!,
                    ppsBytes.bindMemory(to: UInt8.self).baseAddress!
                ]
                var sizes = [vps.count, sps.count, pps.count]
                return CMVideoFormatDescriptionCreateFromHEVCParameterSets(
                    allocator: kCFAllocatorDefault,
                    parameterSetCount: 3,
                    parameterSetPointers: &pointers,
                    parameterSetSizes: &sizes,
                    nalUnitHeaderLength: 4,
                    extensions: nil,
                    formatDescriptionOut: &formatDescription
                )
            }
        }
    }
    guard status == noErr, let formatDescription else {
        throw RuntimeError("CMVideoFormatDescriptionCreateFromHEVCParameterSets failed: \(status)")
    }
    return formatDescription
}

func isParameterSet(codec: UInt8, unit: AnnexBNALUnit) -> Bool {
    if codec == CodecID.h264.rawValue {
        return [7, 8].contains(h264NALType(unit.data))
    }
    if codec == CodecID.hevc.rawValue {
        return [32, 33, 34].contains(hevcNALType(unit.data))
    }
    return false
}

func lengthPrefixedAccessUnit(codec: UInt8, units: [AnnexBNALUnit]) -> Data {
    var output = Data()
    for unit in units where !isParameterSet(codec: codec, unit: unit) {
        var length = UInt32(unit.data.count).bigEndian
        withUnsafeBytes(of: &length) { output.append(contentsOf: $0) }
        output.append(unit.data)
    }
    return output
}

func makeSampleBuffer(
    header: FrameHeader,
    payload: Data,
    formatDescription: CMVideoFormatDescription
) throws -> CMSampleBuffer {
    var blockBuffer: CMBlockBuffer?
    let createStatus = CMBlockBufferCreateWithMemoryBlock(
        allocator: kCFAllocatorDefault,
        memoryBlock: nil,
        blockLength: payload.count,
        blockAllocator: kCFAllocatorDefault,
        customBlockSource: nil,
        offsetToData: 0,
        dataLength: payload.count,
        flags: 0,
        blockBufferOut: &blockBuffer
    )
    guard createStatus == noErr, let blockBuffer else {
        throw RuntimeError("CMBlockBufferCreateWithMemoryBlock failed: \(createStatus)")
    }
    let replaceStatus = payload.withUnsafeBytes {
        CMBlockBufferReplaceDataBytes(
            with: $0.baseAddress!,
            blockBuffer: blockBuffer,
            offsetIntoDestination: 0,
            dataLength: payload.count
        )
    }
    guard replaceStatus == noErr else {
        throw RuntimeError("CMBlockBufferReplaceDataBytes failed: \(replaceStatus)")
    }

    let fps = max(Int32(header.fps), 1)
    let pts = CMTime(value: CMTimeValue(header.frameID), timescale: fps)
    var timing = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: fps),
        presentationTimeStamp: pts,
        decodeTimeStamp: .invalid
    )
    var sampleSize = payload.count
    var sampleBuffer: CMSampleBuffer?
    let sampleStatus = CMSampleBufferCreateReady(
        allocator: kCFAllocatorDefault,
        dataBuffer: blockBuffer,
        formatDescription: formatDescription,
        sampleCount: 1,
        sampleTimingEntryCount: 1,
        sampleTimingArray: &timing,
        sampleSizeEntryCount: 1,
        sampleSizeArray: &sampleSize,
        sampleBufferOut: &sampleBuffer
    )
    guard sampleStatus == noErr, let sampleBuffer else {
        throw RuntimeError("CMSampleBufferCreateReady failed: \(sampleStatus)")
    }

    if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true) {
        let attachment = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
        CFDictionarySetValue(
            attachment,
            Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
            Unmanaged.passUnretained(kCFBooleanTrue).toOpaque()
        )
        if !header.isKeyframe {
            CFDictionarySetValue(
                attachment,
                Unmanaged.passUnretained(kCMSampleAttachmentKey_NotSync).toOpaque(),
                Unmanaged.passUnretained(kCFBooleanTrue).toOpaque()
            )
        }
    }

    return sampleBuffer
}

final class ReceiverViewController: NSViewController {
    let displayLayer = AVSampleBufferDisplayLayer()
    private let statusLabel = NSTextField(labelWithString: "Waiting for iBridge stream")
    private var displayedFrames: UInt64 = 0

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 1280, height: 720))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor

        displayLayer.videoGravity = .resizeAspect
        displayLayer.backgroundColor = NSColor.black.cgColor
        view.layer?.addSublayer(displayLayer)

        statusLabel.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        statusLabel.textColor = .white
        statusLabel.backgroundColor = NSColor.black.withAlphaComponent(0.55)
        statusLabel.drawsBackground = true
        statusLabel.isBezeled = false
        statusLabel.lineBreakMode = .byTruncatingTail
        view.addSubview(statusLabel)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        displayLayer.frame = view.bounds
        statusLabel.frame = NSRect(x: 16, y: view.bounds.height - 44, width: min(760, view.bounds.width - 32), height: 24)
    }

    nonisolated func enqueue(_ sampleBuffer: CMSampleBuffer, header: FrameHeader) {
        let sendableSampleBuffer = SendableSampleBuffer(value: sampleBuffer)
        DispatchQueue.main.async {
            if self.displayLayer.status == .failed {
                self.displayLayer.flush()
            }
            self.displayLayer.enqueue(sendableSampleBuffer.value)
            self.displayedFrames += 1
            if self.displayedFrames % 30 == 1 {
                self.statusLabel.stringValue = "iBridge \(header.width)x\(header.height)@\(header.fps) frame \(header.frameID) dropped_before \(header.droppedBefore)"
            }
        }
    }

    nonisolated func setStatus(_ text: String) {
        DispatchQueue.main.async {
            self.statusLabel.stringValue = text
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let options: Options
    private let receiver = ReceiverViewController()
    private var window: NSWindow?
    private var server: TCPReceiver?

    init(options: Options) {
        self.options = options
    }

    func applicationDidFinishLaunching(_: Notification) {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 720)
        let style: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        let window = NSWindow(
            contentRect: NSRect(x: 80, y: 80, width: min(1280, screenFrame.width), height: min(720, screenFrame.height)),
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        window.title = options.title
        window.contentViewController = receiver
        window.makeKeyAndOrderFront(nil)
        self.window = window

        if options.fullscreen {
            window.toggleFullScreen(nil)
        }

        let server = TCPReceiver(port: options.port, viewController: receiver)
        self.server = server
        server.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        true
    }
}

final class TCPReceiver: @unchecked Sendable {
    private let port: Int
    private weak var viewController: ReceiverViewController?
    private let queue = DispatchQueue(label: "iBridgeReceiverMac.TCPReceiver")

    init(port: Int, viewController: ReceiverViewController) {
        self.port = port
        self.viewController = viewController
    }

    func start() {
        queue.async { [weak self] in
            guard let self else { return }
            do {
                try self.run()
            } catch {
                self.viewController?.setStatus("receiver error: \(error)")
                fputs("receiver error: \(error)\n", stderr)
            }
        }
    }

    private func run() throws {
        let listenFD = socket(AF_INET, SOCK_STREAM, 0)
        guard listenFD >= 0 else {
            throw RuntimeError("socket failed")
        }
        defer { close(listenFD) }

        var yes: Int32 = 1
        setsockopt(listenFD, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout<Int32>.size))

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = UInt16(port).bigEndian
        address.sin_addr = in_addr(s_addr: INADDR_ANY.bigEndian)

        let bindStatus = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(listenFD, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindStatus == 0 else {
            throw RuntimeError("bind failed on port \(port): errno \(errno)")
        }
        guard listen(listenFD, 1) == 0 else {
            throw RuntimeError("listen failed: errno \(errno)")
        }

        viewController?.setStatus("Listening on TCP \(port)")
        print("iBridge macOS receiver listening on TCP \(port)")

        while true {
            let clientFD = accept(listenFD, nil, nil)
            guard clientFD >= 0 else {
                if errno == EINTR { continue }
                throw RuntimeError("accept failed: errno \(errno)")
            }
            handleClient(clientFD)
            close(clientFD)
        }
    }

    private func handleClient(_ fd: Int32) {
        viewController?.setStatus("Primary connected")
        print("primary connected")
        let formatBuilder = FormatDescriptionBuilder()
        var lastFrameID: UInt64?
        var receivedFrames: UInt64 = 0

        do {
            let handshake = try readLine(fd: fd, limit: 4096)
            print("handshake=\(handshake)")
            while true {
                let headerData = try readExact(fd: fd, byteCount: FrameHeader.byteCount)
                let header = try FrameHeader(headerData)
                let payload = try readExact(fd: fd, byteCount: Int(header.payloadLen))
                let units = annexBNALUnits(from: payload)
                guard !units.isEmpty else {
                    throw RuntimeError("frame \(header.frameID) has no Annex-B NAL units")
                }
                guard let format = try formatBuilder.update(codec: header.codec, units: units) else {
                    if header.isKeyframe {
                        print("waiting for parameter sets on keyframe \(header.frameID)")
                    }
                    continue
                }
                let accessUnit = lengthPrefixedAccessUnit(codec: header.codec, units: units)
                guard !accessUnit.isEmpty else { continue }
                let sampleBuffer = try makeSampleBuffer(header: header, payload: accessUnit, formatDescription: format)

                if let lastFrameID, header.frameID > lastFrameID + 1 {
                    print("receiver_missing_frames=\(header.frameID - lastFrameID - 1) before=\(header.frameID)")
                }
                lastFrameID = header.frameID
                receivedFrames += 1
                if receivedFrames % 60 == 1 {
                    print("received_frame=\(header.frameID) size=\(header.width)x\(header.height) payload=\(header.payloadLen) keyframe=\(header.isKeyframe)")
                }
                viewController?.enqueue(sampleBuffer, header: header)
            }
        } catch {
            print("client disconnected or failed: \(error)")
            viewController?.setStatus("Disconnected: \(receivedFrames) frames")
        }
    }
}

func readLine(fd: Int32, limit: Int) throws -> String {
    var data = Data()
    var byte: UInt8 = 0
    while data.count < limit {
        let count = Darwin.recv(fd, &byte, 1, 0)
        if count == 0 {
            throw RuntimeError("connection closed while reading handshake")
        }
        if count < 0 {
            throw RuntimeError("recv failed while reading handshake: errno \(errno)")
        }
        if byte == UInt8(ascii: "\n") {
            return String(decoding: data, as: UTF8.self)
        }
        data.append(byte)
    }
    throw RuntimeError("handshake exceeded \(limit) bytes")
}

func readExact(fd: Int32, byteCount: Int) throws -> Data {
    var data = Data(count: byteCount)
    try data.withUnsafeMutableBytes { rawBuffer in
        guard let base = rawBuffer.baseAddress else { return }
        var offset = 0
        while offset < byteCount {
            let count = Darwin.recv(fd, base.advanced(by: offset), byteCount - offset, 0)
            if count == 0 {
                throw RuntimeError("connection closed")
            }
            if count < 0 {
                if errno == EINTR { continue }
                throw RuntimeError("recv failed: errno \(errno)")
            }
            offset += count
        }
    }
    return data
}

do {
    let options = try parseOptions(CommandLine.arguments)
    let app = NSApplication.shared
    let delegate = AppDelegate(options: options)
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.activate(ignoringOtherApps: true)
    app.run()
} catch {
    fputs("error: \(error)\n\n", stderr)
    usage()
    exit(1)
}
