import CoreMedia
import CoreVideo
import Darwin
import Foundation
import VideoToolbox

struct Options {
    var synthetic = false
    var width = 2560
    var height = 1440
    var fps = 60
    var durationSeconds = 2
    var codec = "h264"
    var csvPath = ""
    var realtime = true
    var sendHost = ""
    var sendPort = 48320
    var bitrateMbps = 0
    var lowLatencyRateControl = true
    var maxKeyFrameInterval = 60
    var maxKeyFrameIntervalDuration = 2.0
    var senderQueueDepth = 4
    var listEncoders = false
    var printSupportedProperties = false
}

struct EncodedFrame {
    let frameID: Int
    let generateMS: Double
    let encodeLatencyMS: Double
    let payloadExtractMS: Double
    let enqueueMS: Double
    let queueDepth: Int
    let droppedBefore: UInt32
    var sendMS: Double
    var bytesSent: Int
    var frameAgeAtSendMS: Double
    var sendFailed: Bool
    let keyframe: Bool
    var senderDropped: Bool
    let payloadBytes: Int
    let status: OSStatus
}

final class EncoderState {
    private let lock = NSLock()
    private var timings: [Int: FrameTiming] = [:]
    private var framesByID: [Int: EncodedFrame] = [:]
    var sender: AsyncTcpFrameSender?

    func markFrame(_ frameID: Int, generateMS: Double) {
        lock.lock()
        let now = DispatchTime.now()
        timings[frameID] = FrameTiming(
            generateMS: generateMS,
            captureNS: now.uptimeNanoseconds,
            encodeStartNS: now.uptimeNanoseconds
        )
        lock.unlock()
    }

    func finishFrame(_ frameID: Int, status: OSStatus, sampleBuffer: CMSampleBuffer?) {
        let callbackStart = DispatchTime.now()
        lock.lock()
        let timing = timings.removeValue(forKey: frameID) ?? FrameTiming(
            generateMS: 0,
            captureNS: callbackStart.uptimeNanoseconds,
            encodeStartNS: callbackStart.uptimeNanoseconds
        )
        lock.unlock()

        let elapsedNS = callbackStart.uptimeNanoseconds - timing.encodeStartNS
        let payloadStart = DispatchTime.now()
        var payload = Data()
        if let sampleBuffer {
            do {
                payload = try encodedPayload(from: sampleBuffer)
            } catch {
                fputs("payload extraction failed for frame \(frameID): \(error)\n", stderr)
            }
        }
        let payloadExtractMS = Double(DispatchTime.now().uptimeNanoseconds - payloadStart.uptimeNanoseconds) / 1_000_000.0
        let keyframe = sampleBuffer.map(sampleBufferIsKeyframe) ?? false
        var enqueueMS = 0.0
        var queueDepth = 0
        var droppedBefore = sender?.droppedFrameCount ?? 0

        if status == noErr, let sender, !payload.isEmpty {
            let enqueueResult = sender.enqueue(
                QueuedFrame(
                    frameID: UInt64(frameID),
                    width: UInt16(sender.width),
                    height: UInt16(sender.height),
                    fps: UInt16(sender.fps),
                    codec: sender.codecID,
                    keyframe: keyframe,
                    captureNS: timing.captureNS,
                    encodeStartNS: timing.encodeStartNS,
                    encodeDoneNS: callbackStart.uptimeNanoseconds,
                    payload: payload
                )
            )
            enqueueMS = enqueueResult.enqueueMS
            queueDepth = enqueueResult.queueDepth
            droppedBefore = enqueueResult.droppedBefore
        }

        let frame = EncodedFrame(
            frameID: frameID,
            generateMS: timing.generateMS,
            encodeLatencyMS: Double(elapsedNS) / 1_000_000.0,
            payloadExtractMS: payloadExtractMS,
            enqueueMS: enqueueMS,
            queueDepth: queueDepth,
            droppedBefore: droppedBefore,
            sendMS: 0,
            bytesSent: 0,
            frameAgeAtSendMS: 0,
            sendFailed: false,
            keyframe: keyframe,
            senderDropped: false,
            payloadBytes: payload.count,
            status: status
        )

        lock.lock()
        framesByID[frameID] = frame
        lock.unlock()
    }

    func markSenderDropped(frameID: UInt64) {
        lock.lock()
        if var frame = framesByID[Int(frameID)] {
            frame.senderDropped = true
            framesByID[Int(frameID)] = frame
        }
        lock.unlock()
    }

    func recordSend(frameID: UInt64, sendMS: Double, bytesSent: Int, frameAgeAtSendMS: Double, droppedBefore: UInt32, failed: Bool) {
        lock.lock()
        if var frame = framesByID[Int(frameID)] {
            frame.sendMS = sendMS
            frame.bytesSent = bytesSent
            frame.frameAgeAtSendMS = frameAgeAtSendMS
            frame.sendFailed = failed
            framesByID[Int(frameID)] = frame
        }
        lock.unlock()
    }

    func sortedFrames() -> [EncodedFrame] {
        lock.lock()
        let output = framesByID.values.sorted { $0.frameID < $1.frameID }
        lock.unlock()
        return output
    }
}

struct FrameTiming {
    let generateMS: Double
    let captureNS: UInt64
    let encodeStartNS: UInt64
}

enum ProtocolV0 {
    static let magic = UInt32(littleEndian: 0x4752_4249)
    static let version = UInt16(0)
    static let headerLen = UInt16(80)
    static let colorNV12 = UInt8(1)
    static let flagKeyframe = UInt32(1 << 0)
    static let flagEndOfFrame = UInt32(1 << 2)
}

struct QueuedFrame {
    let frameID: UInt64
    let width: UInt16
    let height: UInt16
    let fps: UInt16
    let codec: UInt8
    let keyframe: Bool
    let captureNS: UInt64
    let encodeStartNS: UInt64
    let encodeDoneNS: UInt64
    let payload: Data
}

struct EnqueueResult {
    let enqueueMS: Double
    let queueDepth: Int
    let droppedBefore: UInt32
}

final class AsyncTcpFrameSender: @unchecked Sendable {
    let width: Int
    let height: Int
    let fps: Int
    let codecID: UInt8
    var droppedFrameCount: UInt32 {
        condition.lock()
        let count = droppedFrames
        condition.unlock()
        return count
    }

    private let fd: Int32
    private let condition = NSCondition()
    private let maxDepth: Int
    private let sessionID: UInt64
    private var queue: [QueuedFrame] = []
    private var droppedFrames: UInt32 = 0
    private var stopping = false
    private let workerQueue = DispatchQueue(label: "iBridgePrimary.AsyncTcpFrameSender")
    private let workerGroup = DispatchGroup()
    private let onSent: (UInt64, Double, Int, Double, UInt32, Bool) -> Void
    private let onDropped: (UInt64) -> Void

    init(
        host: String,
        port: Int,
        width: Int,
        height: Int,
        fps: Int,
        codec: String,
        maxDepth: Int,
        onSent: @escaping (UInt64, Double, Int, Double, UInt32, Bool) -> Void,
        onDropped: @escaping (UInt64) -> Void
    ) throws {
        self.width = width
        self.height = height
        self.fps = fps
        self.codecID = codec == "hevc" ? 2 : 1
        self.maxDepth = max(1, maxDepth)
        self.sessionID = UInt64.random(in: 1...UInt64.max)
        self.onSent = onSent
        self.onDropped = onDropped

        fd = socket(AF_INET, SOCK_STREAM, 0)
        guard fd >= 0 else {
            throw RuntimeError("socket failed")
        }
        var noSigPipe: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int32>.size))

        var hints = addrinfo(
            ai_flags: 0,
            ai_family: AF_UNSPEC,
            ai_socktype: SOCK_STREAM,
            ai_protocol: IPPROTO_TCP,
            ai_addrlen: 0,
            ai_canonname: nil,
            ai_addr: nil,
            ai_next: nil
        )
        var results: UnsafeMutablePointer<addrinfo>?
        let gai = getaddrinfo(host, String(port), &hints, &results)
        guard gai == 0, let results else {
            close(fd)
            throw RuntimeError("getaddrinfo failed for \(host):\(port)")
        }
        defer { freeaddrinfo(results) }

        var connected = false
        var cursor: UnsafeMutablePointer<addrinfo>? = results
        while let info = cursor {
            if connect(fd, info.pointee.ai_addr, info.pointee.ai_addrlen) == 0 {
                connected = true
                break
            }
            cursor = info.pointee.ai_next
        }
        guard connected else {
            close(fd)
            throw RuntimeError("connect failed for \(host):\(port)")
        }

        let handshake = """
        {"magic":"IBRIDGE","version":0,"role":"primary","session_id":\(sessionID),"selected_codec":"\(codec)","width":\(width),"height":\(height),"fps":\(fps),"frame_transport":"tcp"}\n
        """
        try sendAll(Data(handshake.utf8))

        workerGroup.enter()
        workerQueue.async { [weak self] in
            self?.runWorker()
            self?.workerGroup.leave()
        }
    }

    deinit {
        finishAndWait()
        close(fd)
    }

    func enqueue(_ frame: QueuedFrame) -> EnqueueResult {
        let start = DispatchTime.now()
        var droppedFrameID: UInt64?
        condition.lock()
        if queue.count >= maxDepth {
            let dropIndex = queue.firstIndex { !$0.keyframe } ?? 0
            droppedFrameID = queue.remove(at: dropIndex).frameID
            droppedFrames = droppedFrames == UInt32.max ? UInt32.max : droppedFrames + 1
        }
        queue.append(frame)
        let depth = queue.count
        let droppedBefore = droppedFrames
        condition.signal()
        condition.unlock()

        if let droppedFrameID {
            onDropped(droppedFrameID)
        }

        let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
        return EnqueueResult(
            enqueueMS: Double(elapsed) / 1_000_000.0,
            queueDepth: depth,
            droppedBefore: droppedBefore
        )
    }

    func finishAndWait() {
        condition.lock()
        stopping = true
        condition.signal()
        condition.unlock()
        workerGroup.wait()
    }

    private func runWorker() {
        while true {
            condition.lock()
            while queue.isEmpty && !stopping {
                condition.wait()
            }
            if queue.isEmpty && stopping {
                condition.unlock()
                return
            }
            let frame = queue.removeFirst()
            let droppedBefore = droppedFrames
            condition.unlock()

            let sendStart = DispatchTime.now()
            let frameAgeMS = Double(sendStart.uptimeNanoseconds - frame.captureNS) / 1_000_000.0
            do {
                let bytesSent = try sendPacket(frame: frame, droppedBefore: droppedBefore, sendNS: sendStart.uptimeNanoseconds)
                let sendMS = Double(DispatchTime.now().uptimeNanoseconds - sendStart.uptimeNanoseconds) / 1_000_000.0
                onSent(frame.frameID, sendMS, bytesSent, frameAgeMS, droppedBefore, false)
            } catch {
                let sendMS = Double(DispatchTime.now().uptimeNanoseconds - sendStart.uptimeNanoseconds) / 1_000_000.0
                fputs("transport send failed for frame \(frame.frameID): \(error)\n", stderr)
                onSent(frame.frameID, sendMS, 0, frameAgeMS, droppedBefore, true)
            }
        }
    }

    private func sendPacket(frame: QueuedFrame, droppedBefore: UInt32, sendNS: UInt64) throws -> Int {
        var packet = Data()
        appendLE(&packet, ProtocolV0.magic)
        appendLE(&packet, ProtocolV0.version)
        appendLE(&packet, ProtocolV0.headerLen)
        appendLE(&packet, sessionID)
        appendLE(&packet, frame.frameID)
        appendLE(&packet, UInt16(0))
        appendLE(&packet, UInt16(1))
        appendLE(&packet, frame.width)
        appendLE(&packet, frame.height)
        appendLE(&packet, frame.fps)
        packet.append(frame.codec)
        packet.append(ProtocolV0.colorNV12)
        let keyframeFlag = frame.keyframe ? ProtocolV0.flagKeyframe : 0
        appendLE(&packet, keyframeFlag | ProtocolV0.flagEndOfFrame)
        appendLE(&packet, frame.captureNS)
        appendLE(&packet, frame.encodeStartNS)
        appendLE(&packet, frame.encodeDoneNS)
        appendLE(&packet, sendNS)
        appendLE(&packet, UInt32(frame.payload.count))
        appendLE(&packet, droppedBefore)
        precondition(packet.count == Int(ProtocolV0.headerLen))
        packet.append(frame.payload)

        try sendAll(packet)
        return packet.count
    }

    private func sendAll(_ data: Data) throws {
        try data.withUnsafeBytes { rawBuffer in
            guard let base = rawBuffer.baseAddress else { return }
            var sent = 0
            while sent < rawBuffer.count {
                let result = Darwin.send(fd, base.advanced(by: sent), rawBuffer.count - sent, 0)
                if result <= 0 {
                    throw RuntimeError("send failed")
                }
                sent += result
            }
        }
    }
}

func appendLE<T: FixedWidthInteger>(_ data: inout Data, _ value: T) {
    var little = value.littleEndian
    withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
}

func encodedPayload(from sampleBuffer: CMSampleBuffer) throws -> Data {
    guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
        throw RuntimeError("sample buffer has no data buffer")
    }
    let length = CMBlockBufferGetDataLength(blockBuffer)
    var data = Data(count: length)
    let status = data.withUnsafeMutableBytes { rawBuffer in
        CMBlockBufferCopyDataBytes(
            blockBuffer,
            atOffset: 0,
            dataLength: length,
            destination: rawBuffer.baseAddress!
        )
    }
    guard status == noErr else {
        throw RuntimeError("CMBlockBufferCopyDataBytes failed: \(status)")
    }
    return data
}

func sampleBufferIsKeyframe(_ sampleBuffer: CMSampleBuffer) -> Bool {
    guard let attachments = CMSampleBufferGetSampleAttachmentsArray(
        sampleBuffer,
        createIfNecessary: false
    ) as? [[CFString: Any]],
        let first = attachments.first,
        let notSync = first[kCMSampleAttachmentKey_NotSync] as? Bool else {
        return true
    }
    return !notSync
}

func compressionOutputCallback(
    _ outputCallbackRefCon: UnsafeMutableRawPointer?,
    _ sourceFrameRefCon: UnsafeMutableRawPointer?,
    _ status: OSStatus,
    _: VTEncodeInfoFlags,
    _ sampleBuffer: CMSampleBuffer?
) {

    guard let outputCallbackRefCon else { return }
    let state = Unmanaged<EncoderState>
        .fromOpaque(outputCallbackRefCon)
        .takeUnretainedValue()
    let frameID = Int(bitPattern: sourceFrameRefCon) - 1
    state.finishFrame(frameID, status: status, sampleBuffer: sampleBuffer)
}

func usage() {
    print("""
    ibridge-primary --synthetic --resolution 2560x1440 --fps 60 --duration 2 --codec h264 --csv diagnostics.csv [--bitrate-mbps 120] [--no-realtime] [--send-host host --send-port 48320] [--sender-queue-depth 4]
    ibridge-primary --list-encoders
    """)
}

func parseResolution(_ text: String) throws -> (Int, Int) {
    let parts = text.lowercased().split(separator: "x")
    guard parts.count == 2, let width = Int(parts[0]), let height = Int(parts[1]),
          width > 0, height > 0 else {
        throw RuntimeError("resolution must look like 2560x1440")
    }
    return (width, height)
}

struct RuntimeError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) {
        self.description = description
    }
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
        } else if arg == "--synthetic" {
            options.synthetic = true
        } else if arg == "--resolution" {
            let parsed = try parseResolution(try value())
            options.width = parsed.0
            options.height = parsed.1
        } else if arg.hasPrefix("--resolution=") {
            let parsed = try parseResolution(String(arg.dropFirst("--resolution=".count)))
            options.width = parsed.0
            options.height = parsed.1
        } else if arg == "--fps" {
            options.fps = try Int(value()) ?? options.fps
        } else if arg.hasPrefix("--fps=") {
            options.fps = Int(arg.dropFirst("--fps=".count)) ?? options.fps
        } else if arg == "--duration" {
            options.durationSeconds = try Int(value()) ?? options.durationSeconds
        } else if arg.hasPrefix("--duration=") {
            options.durationSeconds = Int(arg.dropFirst("--duration=".count)) ?? options.durationSeconds
        } else if arg == "--codec" {
            options.codec = try value().lowercased()
        } else if arg.hasPrefix("--codec=") {
            options.codec = String(arg.dropFirst("--codec=".count)).lowercased()
        } else if arg == "--csv" {
            options.csvPath = try value()
        } else if arg.hasPrefix("--csv=") {
            options.csvPath = String(arg.dropFirst("--csv=".count))
        } else if arg == "--send-host" {
            options.sendHost = try value()
        } else if arg.hasPrefix("--send-host=") {
            options.sendHost = String(arg.dropFirst("--send-host=".count))
        } else if arg == "--send-port" {
            options.sendPort = try Int(value()) ?? options.sendPort
        } else if arg.hasPrefix("--send-port=") {
            options.sendPort = Int(arg.dropFirst("--send-port=".count)) ?? options.sendPort
        } else if arg == "--bitrate-mbps" {
            options.bitrateMbps = try Int(value()) ?? options.bitrateMbps
        } else if arg.hasPrefix("--bitrate-mbps=") {
            options.bitrateMbps = Int(arg.dropFirst("--bitrate-mbps=".count)) ?? options.bitrateMbps
        } else if arg == "--sender-queue-depth" {
            options.senderQueueDepth = try Int(value()) ?? options.senderQueueDepth
        } else if arg.hasPrefix("--sender-queue-depth=") {
            options.senderQueueDepth = Int(arg.dropFirst("--sender-queue-depth=".count)) ?? options.senderQueueDepth
        } else if arg == "--max-keyframe-interval" {
            options.maxKeyFrameInterval = try Int(value()) ?? options.maxKeyFrameInterval
        } else if arg.hasPrefix("--max-keyframe-interval=") {
            options.maxKeyFrameInterval = Int(arg.dropFirst("--max-keyframe-interval=".count)) ?? options.maxKeyFrameInterval
        } else if arg == "--max-keyframe-interval-duration" {
            options.maxKeyFrameIntervalDuration = try Double(value()) ?? options.maxKeyFrameIntervalDuration
        } else if arg.hasPrefix("--max-keyframe-interval-duration=") {
            options.maxKeyFrameIntervalDuration = Double(arg.dropFirst("--max-keyframe-interval-duration=".count)) ?? options.maxKeyFrameIntervalDuration
        } else if arg == "--disable-low-latency-rate-control" {
            options.lowLatencyRateControl = false
        } else if arg == "--list-encoders" {
            options.listEncoders = true
        } else if arg == "--print-supported-properties" {
            options.printSupportedProperties = true
        } else if arg == "--no-realtime" {
            options.realtime = false
        } else {
            throw RuntimeError("unknown argument: \(arg)")
        }
        index += 1
    }

    if options.listEncoders {
        return options
    }
    guard options.synthetic else {
        throw RuntimeError("only --synthetic exists in the first Primary spike")
    }
    guard options.fps > 0, options.durationSeconds > 0 else {
        throw RuntimeError("--fps and --duration must be positive")
    }
    guard options.codec == "h264" || options.codec == "hevc" else {
        throw RuntimeError("--codec must be h264 or hevc")
    }
    guard options.senderQueueDepth > 0 else {
        throw RuntimeError("--sender-queue-depth must be positive")
    }
    return options
}

func makePixelBuffer(width: Int, height: Int, frameID: Int) throws -> (CVPixelBuffer, Double) {
    let start = DispatchTime.now()
    var pixelBuffer: CVPixelBuffer?
    let attrs: [CFString: Any] = [
        kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey: width,
        kCVPixelBufferHeightKey: height,
        kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary
    ]
    let status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_32BGRA,
        attrs as CFDictionary,
        &pixelBuffer
    )
    guard status == kCVReturnSuccess, let pixelBuffer else {
        throw RuntimeError("CVPixelBufferCreate failed: \(status)")
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
        throw RuntimeError("pixel buffer has no base address")
    }

    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let frame = UInt32(frameID & 0xff)
    for y in 0..<height {
        let row = baseAddress.advanced(by: y * bytesPerRow)
            .assumingMemoryBound(to: UInt32.self)
        let gy = UInt32((y + Int(frame)) & 0xff)
        for x in 0..<width {
            let bx = UInt32((x + Int(frame)) & 0xff)
            let r = UInt32(((x >> 5) + (y >> 5) + Int(frame)) & 0xff)
            row[x] = 0xff00_0000 | (r << 16) | (gy << 8) | bx
        }
    }

    let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
    return (pixelBuffer, Double(elapsed) / 1_000_000.0)
}

func codecType(_ codec: String) -> CMVideoCodecType {
    codec == "hevc" ? kCMVideoCodecType_HEVC : kCMVideoCodecType_H264
}

func encoderSpecification(options: Options) -> CFDictionary? {
    guard options.lowLatencyRateControl else { return nil }
    let spec: [String: Any] = [
        kVTVideoEncoderSpecification_EnableLowLatencyRateControl as String: true
    ]
    return spec as CFDictionary
}

func configure(_ session: VTCompressionSession, options: Options) throws {
    let bitrate = options.bitrateMbps > 0
        ? options.bitrateMbps * 1_000_000
        : options.width * options.height * options.fps * 2

    func setProperty(_ key: CFString, _ value: Any, required: Bool = true) throws {
        let status = VTSessionSetProperty(session, key: key, value: value as CFTypeRef)
        if status != noErr && required {
            throw RuntimeError("VTSessionSetProperty \(key) failed: \(status)")
        } else if status != noErr {
            fputs("warning: VTSessionSetProperty \(key) failed: \(status)\n", stderr)
        }
    }

    try setProperty(kVTCompressionPropertyKey_RealTime, kCFBooleanTrue as Any)
    try setProperty(kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse as Any)
    try setProperty(kVTCompressionPropertyKey_AllowTemporalCompression, kCFBooleanFalse as Any, required: false)
    try setProperty(kVTCompressionPropertyKey_ExpectedFrameRate, options.fps)
    try setProperty(kVTCompressionPropertyKey_MaxKeyFrameInterval, options.maxKeyFrameInterval)
    try setProperty(kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, options.maxKeyFrameIntervalDuration)
    try setProperty(kVTCompressionPropertyKey_AverageBitRate, bitrate)

    let prepareStatus = VTCompressionSessionPrepareToEncodeFrames(session)
    guard prepareStatus == noErr else {
        throw RuntimeError("VTCompressionSessionPrepareToEncodeFrames failed: \(prepareStatus)")
    }
}

func printSupportedProperties(for session: VTCompressionSession) {
    var dictionary: CFDictionary?
    let status = VTSessionCopySupportedPropertyDictionary(
        session,
        supportedPropertyDictionaryOut: &dictionary
    )
    guard status == noErr else {
        fputs("warning: VTSessionCopySupportedPropertyDictionary failed: \(status)\n", stderr)
        return
    }
    print("supported_properties=\(String(describing: dictionary))")
}

func printVideoEncoderList() throws {
    var encoderList: CFArray?
    let status = VTCopyVideoEncoderList(nil, &encoderList)
    guard status == noErr else {
        throw RuntimeError("VTCopyVideoEncoderList failed: \(status)")
    }
    print("video_encoder_list=\(String(describing: encoderList))")
}

func writeCSV(path: String, frames: [EncodedFrame]) throws {
    guard !path.isEmpty else { return }
    var output = "frame_id,generate_ms,encode_latency_ms,payload_extract_ms,enqueue_ms,queue_depth,dropped_before,send_ms,bytes_sent,frame_age_at_send_ms,send_failed,keyframe,sender_dropped,payload_bytes,status\n"
    for frame in frames {
        output += "\(frame.frameID),"
        output += String(format: "%.4f,%.4f,%.4f,%.4f,", frame.generateMS, frame.encodeLatencyMS, frame.payloadExtractMS, frame.enqueueMS)
        output += "\(frame.queueDepth),\(frame.droppedBefore),"
        output += String(format: "%.4f,%d,%.4f,", frame.sendMS, frame.bytesSent, frame.frameAgeAtSendMS)
        output += "\(frame.sendFailed ? 1 : 0),\(frame.keyframe ? 1 : 0),\(frame.senderDropped ? 1 : 0),"
        output += "\(frame.payloadBytes),\(frame.status)\n"
    }
    try FileManager.default.createDirectory(
        atPath: URL(fileURLWithPath: path).deletingLastPathComponent().path,
        withIntermediateDirectories: true
    )
    try output.write(toFile: path, atomically: true, encoding: .utf8)
}

func percentile(_ values: [Double], _ p: Double) -> Double {
    guard !values.isEmpty else { return 0 }
    let sorted = values.sorted()
    let rawIndex = (p / 100.0) * Double(sorted.count - 1)
    let lower = Int(rawIndex)
    let upper = min(lower + 1, sorted.count - 1)
    let fraction = rawIndex - Double(lower)
    return sorted[lower] * (1 - fraction) + sorted[upper] * fraction
}

func runSynthetic(options: Options) throws {
    let state = EncoderState()
    if !options.sendHost.isEmpty {
        state.sender = try AsyncTcpFrameSender(
            host: options.sendHost,
            port: options.sendPort,
            width: options.width,
            height: options.height,
            fps: options.fps,
            codec: options.codec,
            maxDepth: options.senderQueueDepth,
            onSent: { [weak state] frameID, sendMS, bytesSent, frameAgeAtSendMS, droppedBefore, failed in
                state?.recordSend(
                    frameID: frameID,
                    sendMS: sendMS,
                    bytesSent: bytesSent,
                    frameAgeAtSendMS: frameAgeAtSendMS,
                    droppedBefore: droppedBefore,
                    failed: failed
                )
            },
            onDropped: { [weak state] frameID in
                state?.markSenderDropped(frameID: frameID)
            }
        )
    }
    var session: VTCompressionSession?
    let createStatus = VTCompressionSessionCreate(
        allocator: kCFAllocatorDefault,
        width: Int32(options.width),
        height: Int32(options.height),
        codecType: codecType(options.codec),
        encoderSpecification: encoderSpecification(options: options),
        imageBufferAttributes: nil,
        compressedDataAllocator: nil,
        outputCallback: compressionOutputCallback,
        refcon: Unmanaged.passUnretained(state).toOpaque(),
        compressionSessionOut: &session
    )
    guard createStatus == noErr, let session else {
        throw RuntimeError("VTCompressionSessionCreate failed: \(createStatus)")
    }
    defer { VTCompressionSessionInvalidate(session) }

    try configure(session, options: options)
    if options.printSupportedProperties {
        printSupportedProperties(for: session)
    }

    let frameCount = options.fps * options.durationSeconds
    let frameDuration = CMTime(value: 1, timescale: CMTimeScale(options.fps))
    let wallFrameDuration = 1.0 / Double(options.fps)
    let runStart = DispatchTime.now()

    for frameID in 0..<frameCount {
        if options.realtime {
            let target = Double(frameID) * wallFrameDuration
            let elapsed = Double(DispatchTime.now().uptimeNanoseconds - runStart.uptimeNanoseconds) / 1_000_000_000.0
            if target > elapsed {
                Thread.sleep(forTimeInterval: target - elapsed)
            }
        }

        let (pixelBuffer, generateMS) = try makePixelBuffer(
            width: options.width,
            height: options.height,
            frameID: frameID
        )
        state.markFrame(frameID, generateMS: generateMS)
        let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameID))
        let status = VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: pixelBuffer,
            presentationTimeStamp: presentationTime,
            duration: frameDuration,
            frameProperties: nil,
            sourceFrameRefcon: UnsafeMutableRawPointer(bitPattern: frameID + 1),
            infoFlagsOut: nil
        )
        guard status == noErr else {
            state.finishFrame(frameID, status: status, sampleBuffer: nil)
            continue
        }
    }

    VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
    state.sender?.finishAndWait()

    let frames = state.sortedFrames()
    try writeCSV(path: options.csvPath, frames: frames)

    let latencies = frames.map(\.encodeLatencyMS)
    let generateTimes = frames.map(\.generateMS)
    let sendTimes = frames.map(\.sendMS).filter { $0 > 0 }
    let totalBytes = frames.reduce(0) { $0 + $1.payloadBytes }
    let totalBytesSent = frames.reduce(0) { $0 + $1.bytesSent }
    let failed = frames.filter { $0.status != noErr }.count
    let senderDropped = frames.filter(\.senderDropped).count
    let sendFailed = frames.filter(\.sendFailed).count

    print("iBridge Primary synthetic encoder")
    print("resolution=\(options.width)x\(options.height)")
    print("target_fps=\(options.fps)")
    print("duration_seconds=\(options.durationSeconds)")
    print("codec=\(options.codec)")
    print("bitrate_mbps=\(options.bitrateMbps > 0 ? options.bitrateMbps : 0)")
    print("low_latency_rate_control=\(options.lowLatencyRateControl ? "on" : "off")")
    print("max_keyframe_interval=\(options.maxKeyFrameInterval)")
    print(String(format: "max_keyframe_interval_duration=%.3f", options.maxKeyFrameIntervalDuration))
    print("sender_queue_depth=\(options.senderQueueDepth)")
    print("frames_requested=\(frameCount)")
    print("frames_encoded=\(frames.count)")
    print("failed_frames=\(failed)")
    print("sender_dropped_frames=\(senderDropped)")
    print("send_failed_frames=\(sendFailed)")
    print(String(format: "avg_generate_ms=%.3f", generateTimes.reduce(0, +) / Double(max(generateTimes.count, 1))))
    print(String(format: "avg_encode_latency_ms=%.3f", latencies.reduce(0, +) / Double(max(latencies.count, 1))))
    print(String(format: "p95_encode_latency_ms=%.3f", percentile(latencies, 95)))
    print(String(format: "max_encode_latency_ms=%.3f", latencies.max() ?? 0))
    print(String(format: "avg_send_ms=%.3f", sendTimes.reduce(0, +) / Double(max(sendTimes.count, 1))))
    print(String(format: "p95_send_ms=%.3f", percentile(sendTimes, 95)))
    print("payload_bytes=\(totalBytes)")
    print("bytes_sent=\(totalBytesSent)")
    print("send_target=\(options.sendHost.isEmpty ? "none" : "\(options.sendHost):\(options.sendPort)")")
    print("csv=\(options.csvPath.isEmpty ? "none" : options.csvPath)")
}

do {
    let options = try parseOptions(CommandLine.arguments)
    if options.listEncoders {
        try printVideoEncoderList()
    } else {
        try runSynthetic(options: options)
    }
} catch {
    fputs("error: \(error)\n\n", stderr)
    usage()
    exit(1)
}
