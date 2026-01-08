import CoreGraphics
import CoreMedia
import CoreVideo
import Darwin
import Foundation
@preconcurrency import ScreenCaptureKit
import VideoToolbox

struct Options {
    var synthetic = false
    var screenCapture = false
    var source = "synthetic-bgra"
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
    var dataRateLimitMbps = 0
    var dataRateWindowSeconds = 1.0
    var lowLatencyRateControl = true
    var maxKeyFrameInterval = 60
    var maxKeyFrameIntervalDuration = 2.0
    var maxFrameDelayCount: Int? = 0
    var allowTemporalCompression = true
    var allowFrameReordering = false
    var allowOpenGOP = false
    var prioritizeSpeed: Bool?
    var payloadFormat = "length-prefixed"
    var staticChangeEvery = 1
    var captureDisplayIndex = 0
    var captureQueueDepth = 8
    var tileColumns = 2
    var tileRows = 2
    var tileReuseBuffers = false
    var tileMaxInFlightLogicalFrames = 0
    var tileResetEveryFrames = 0
    var warmupFrames = 0
    var senderQueueDepth = 4
    var listEncoders = false
    var printSupportedProperties = false
    var encoderID = ""
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
    let codec: String
    let payloadFormat: String
    let onFrameFinished: ((EncodedFrame) -> Void)?
    var sender: AsyncTcpFrameSender?

    init(codec: String, payloadFormat: String, onFrameFinished: ((EncodedFrame) -> Void)? = nil) {
        self.codec = codec
        self.payloadFormat = payloadFormat
        self.onFrameFinished = onFrameFinished
    }

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
                payload = try encodedPayload(from: sampleBuffer, codec: codec, payloadFormat: payloadFormat)
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
        onFrameFinished?(frame)
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

func encodedPayload(from sampleBuffer: CMSampleBuffer, codec: String, payloadFormat: String) throws -> Data {
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
    guard payloadFormat == "annex-b" else {
        return data
    }

    var annexB = Data()
    if sampleBufferIsKeyframe(sampleBuffer),
       let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
        appendParameterSets(formatDescription, codec: codec, to: &annexB)
    }
    try appendLengthPrefixedNALUnitsAsAnnexB(data, to: &annexB)
    return annexB
}

func appendStartCode(to data: inout Data) {
    data.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
}

func appendParameterSets(_ formatDescription: CMFormatDescription, codec: String, to output: inout Data) {
    if codec == "h264" {
        var parameterSetCount = 0
        var nalUnitHeaderLength: Int32 = 0
        var pointer: UnsafePointer<UInt8>?
        var size = 0
        let countStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
            formatDescription,
            parameterSetIndex: 0,
            parameterSetPointerOut: &pointer,
            parameterSetSizeOut: &size,
            parameterSetCountOut: &parameterSetCount,
            nalUnitHeaderLengthOut: &nalUnitHeaderLength
        )
        guard countStatus == noErr else { return }
        for index in 0..<parameterSetCount {
            pointer = nil
            size = 0
            let status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
                formatDescription,
                parameterSetIndex: index,
                parameterSetPointerOut: &pointer,
                parameterSetSizeOut: &size,
                parameterSetCountOut: nil,
                nalUnitHeaderLengthOut: nil
            )
            if status == noErr, let pointer, size > 0 {
                appendStartCode(to: &output)
                output.append(pointer, count: size)
            }
        }
    } else {
        var parameterSetCount = 0
        var nalUnitHeaderLength: Int32 = 0
        var pointer: UnsafePointer<UInt8>?
        var size = 0
        let countStatus = CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(
            formatDescription,
            parameterSetIndex: 0,
            parameterSetPointerOut: &pointer,
            parameterSetSizeOut: &size,
            parameterSetCountOut: &parameterSetCount,
            nalUnitHeaderLengthOut: &nalUnitHeaderLength
        )
        guard countStatus == noErr else { return }
        for index in 0..<parameterSetCount {
            pointer = nil
            size = 0
            let status = CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(
                formatDescription,
                parameterSetIndex: index,
                parameterSetPointerOut: &pointer,
                parameterSetSizeOut: &size,
                parameterSetCountOut: nil,
                nalUnitHeaderLengthOut: nil
            )
            if status == noErr, let pointer, size > 0 {
                appendStartCode(to: &output)
                output.append(pointer, count: size)
            }
        }
    }
}

func appendLengthPrefixedNALUnitsAsAnnexB(_ payload: Data, to output: inout Data) throws {
    var offset = 0
    while offset < payload.count {
        guard offset + 4 <= payload.count else {
            throw RuntimeError("incomplete NAL length prefix at offset \(offset)")
        }
        let naluLength =
            (UInt32(payload[offset]) << 24)
            | (UInt32(payload[offset + 1]) << 16)
            | (UInt32(payload[offset + 2]) << 8)
            | UInt32(payload[offset + 3])
        offset += 4
        guard naluLength > 0, offset + Int(naluLength) <= payload.count else {
            throw RuntimeError("invalid NAL length \(naluLength) at offset \(offset)")
        }
        appendStartCode(to: &output)
        output.append(payload.subdata(in: offset..<(offset + Int(naluLength))))
        offset += Int(naluLength)
    }
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
    ibridge-primary --synthetic --source synthetic-bgra --resolution 2560x1440 --fps 60 --duration 2 --codec h264 --csv diagnostics.csv [--bitrate-mbps 120] [--no-realtime] [--send-host host --send-port 48320] [--sender-queue-depth 4] [--encoder-id com.apple.videotoolbox.videoencoder.ave.hevc]
    ibridge-primary --screen-capture --source screen-capture --resolution 3840x2160 --fps 60 --duration 5 --codec hevc --csv diagnostics.csv
    ibridge-primary --list-encoders

    Sources:
      --source synthetic-bgra
      --source synthetic-nv12
      --source synthetic-static-skip --static-change-every 60
      --source synthetic-nv12-tiled --tile-columns 2 --tile-rows 2 [--tile-reuse-buffers] [--tile-max-inflight-logical-frames 1] [--tile-reset-every-frames 150]
      --source screen-capture --capture-display-index 0 --capture-queue-depth 8
      --warmup-frames 20

    Reference-informed VideoToolbox options:
      --disable-low-latency-rate-control
      --allow-temporal-compression | --disable-temporal-compression
      --allow-frame-reordering | --disable-frame-reordering
      --allow-open-gop | --disable-open-gop
      --prioritize-speed | --no-prioritize-speed
      --max-frame-delay-count 0 | --no-max-frame-delay-count
      --data-rate-limit-mbps 120 [--data-rate-window 1.0]
      --payload-format length-prefixed|annex-b
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
            if options.source == "screen-capture" {
                options.source = "synthetic-bgra"
            }
        } else if arg == "--screen-capture" {
            options.screenCapture = true
            options.source = "screen-capture"
        } else if arg == "--source" {
            options.source = try value().lowercased()
        } else if arg.hasPrefix("--source=") {
            options.source = String(arg.dropFirst("--source=".count)).lowercased()
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
        } else if arg == "--data-rate-limit-mbps" {
            options.dataRateLimitMbps = try Int(value()) ?? options.dataRateLimitMbps
        } else if arg.hasPrefix("--data-rate-limit-mbps=") {
            options.dataRateLimitMbps = Int(arg.dropFirst("--data-rate-limit-mbps=".count)) ?? options.dataRateLimitMbps
        } else if arg == "--data-rate-window" {
            options.dataRateWindowSeconds = try Double(value()) ?? options.dataRateWindowSeconds
        } else if arg.hasPrefix("--data-rate-window=") {
            options.dataRateWindowSeconds = Double(arg.dropFirst("--data-rate-window=".count)) ?? options.dataRateWindowSeconds
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
        } else if arg == "--max-frame-delay-count" {
            options.maxFrameDelayCount = try Int(value())
        } else if arg.hasPrefix("--max-frame-delay-count=") {
            options.maxFrameDelayCount = Int(arg.dropFirst("--max-frame-delay-count=".count))
        } else if arg == "--no-max-frame-delay-count" {
            options.maxFrameDelayCount = nil
        } else if arg == "--allow-temporal-compression" {
            options.allowTemporalCompression = true
        } else if arg == "--disable-temporal-compression" {
            options.allowTemporalCompression = false
        } else if arg == "--allow-frame-reordering" {
            options.allowFrameReordering = true
        } else if arg == "--disable-frame-reordering" {
            options.allowFrameReordering = false
        } else if arg == "--allow-open-gop" {
            options.allowOpenGOP = true
        } else if arg == "--disable-open-gop" {
            options.allowOpenGOP = false
        } else if arg == "--prioritize-speed" {
            options.prioritizeSpeed = true
        } else if arg == "--no-prioritize-speed" {
            options.prioritizeSpeed = false
        } else if arg == "--payload-format" {
            options.payloadFormat = try value().lowercased()
        } else if arg.hasPrefix("--payload-format=") {
            options.payloadFormat = String(arg.dropFirst("--payload-format=".count)).lowercased()
        } else if arg == "--annex-b" {
            options.payloadFormat = "annex-b"
        } else if arg == "--static-change-every" {
            options.staticChangeEvery = try Int(value()) ?? options.staticChangeEvery
        } else if arg.hasPrefix("--static-change-every=") {
            options.staticChangeEvery = Int(arg.dropFirst("--static-change-every=".count)) ?? options.staticChangeEvery
        } else if arg == "--capture-display-index" {
            options.captureDisplayIndex = try Int(value()) ?? options.captureDisplayIndex
        } else if arg.hasPrefix("--capture-display-index=") {
            options.captureDisplayIndex = Int(arg.dropFirst("--capture-display-index=".count)) ?? options.captureDisplayIndex
        } else if arg == "--capture-queue-depth" {
            options.captureQueueDepth = try Int(value()) ?? options.captureQueueDepth
        } else if arg.hasPrefix("--capture-queue-depth=") {
            options.captureQueueDepth = Int(arg.dropFirst("--capture-queue-depth=".count)) ?? options.captureQueueDepth
        } else if arg == "--tile-columns" {
            options.tileColumns = try Int(value()) ?? options.tileColumns
        } else if arg.hasPrefix("--tile-columns=") {
            options.tileColumns = Int(arg.dropFirst("--tile-columns=".count)) ?? options.tileColumns
        } else if arg == "--tile-rows" {
            options.tileRows = try Int(value()) ?? options.tileRows
        } else if arg.hasPrefix("--tile-rows=") {
            options.tileRows = Int(arg.dropFirst("--tile-rows=".count)) ?? options.tileRows
        } else if arg == "--tile-reuse-buffers" {
            options.tileReuseBuffers = true
        } else if arg == "--tile-max-inflight-logical-frames" {
            options.tileMaxInFlightLogicalFrames = try Int(value()) ?? options.tileMaxInFlightLogicalFrames
        } else if arg.hasPrefix("--tile-max-inflight-logical-frames=") {
            options.tileMaxInFlightLogicalFrames = Int(arg.dropFirst("--tile-max-inflight-logical-frames=".count)) ?? options.tileMaxInFlightLogicalFrames
        } else if arg == "--tile-reset-every-frames" {
            options.tileResetEveryFrames = try Int(value()) ?? options.tileResetEveryFrames
        } else if arg.hasPrefix("--tile-reset-every-frames=") {
            options.tileResetEveryFrames = Int(arg.dropFirst("--tile-reset-every-frames=".count)) ?? options.tileResetEveryFrames
        } else if arg == "--warmup-frames" {
            options.warmupFrames = try Int(value()) ?? options.warmupFrames
        } else if arg.hasPrefix("--warmup-frames=") {
            options.warmupFrames = Int(arg.dropFirst("--warmup-frames=".count)) ?? options.warmupFrames
        } else if arg == "--disable-low-latency-rate-control" {
            options.lowLatencyRateControl = false
        } else if arg == "--encoder-id" {
            options.encoderID = try value()
        } else if arg.hasPrefix("--encoder-id=") {
            options.encoderID = String(arg.dropFirst("--encoder-id=".count))
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
    let validSources = ["synthetic-bgra", "synthetic-nv12", "synthetic-static-skip", "synthetic-nv12-tiled", "screen-capture"]
    guard validSources.contains(options.source) else {
        throw RuntimeError("--source must be one of \(validSources.joined(separator: ", "))")
    }
    if options.source == "screen-capture" {
        options.screenCapture = true
        options.synthetic = false
    } else {
        options.synthetic = true
        options.screenCapture = false
    }
    guard options.synthetic || options.screenCapture else {
        throw RuntimeError("choose --synthetic or --screen-capture")
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
    guard options.dataRateLimitMbps >= 0, options.dataRateWindowSeconds > 0 else {
        throw RuntimeError("--data-rate-limit-mbps must be non-negative and --data-rate-window must be positive")
    }
    guard options.maxFrameDelayCount == nil || options.maxFrameDelayCount! >= 0 else {
        throw RuntimeError("--max-frame-delay-count must be non-negative")
    }
    guard options.payloadFormat == "length-prefixed" || options.payloadFormat == "annex-b" else {
        throw RuntimeError("--payload-format must be length-prefixed or annex-b")
    }
    guard options.staticChangeEvery > 0 else {
        throw RuntimeError("--static-change-every must be positive")
    }
    guard options.captureDisplayIndex >= 0, options.captureQueueDepth > 0 else {
        throw RuntimeError("--capture-display-index must be non-negative and --capture-queue-depth must be positive")
    }
    guard options.warmupFrames >= 0 else {
        throw RuntimeError("--warmup-frames must be non-negative")
    }
    guard options.tileColumns > 0, options.tileRows > 0 else {
        throw RuntimeError("--tile-columns and --tile-rows must be positive")
    }
    guard options.tileMaxInFlightLogicalFrames >= 0 else {
        throw RuntimeError("--tile-max-inflight-logical-frames must be non-negative")
    }
    guard options.tileResetEveryFrames >= 0 else {
        throw RuntimeError("--tile-reset-every-frames must be non-negative")
    }
    if options.source == "synthetic-nv12-tiled" {
        guard options.width % options.tileColumns == 0, options.height % options.tileRows == 0 else {
            throw RuntimeError("resolution must divide evenly by --tile-columns and --tile-rows")
        }
        guard options.sendHost.isEmpty else {
            throw RuntimeError("synthetic-nv12-tiled is an encode benchmark only; live tiled transport is not implemented yet")
        }
    }
    return options
}

func makeBGRAPixelBuffer(width: Int, height: Int, frameID: Int) throws -> (CVPixelBuffer, Double) {
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

func makeNV12PixelBuffer(width: Int, height: Int, frameID: Int) throws -> (CVPixelBuffer, Double) {
    let start = DispatchTime.now()
    var pixelBuffer: CVPixelBuffer?
    let attrs: [CFString: Any] = [
        kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
        kCVPixelBufferWidthKey: width,
        kCVPixelBufferHeightKey: height,
        kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary
    ]
    let status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
        attrs as CFDictionary,
        &pixelBuffer
    )
    guard status == kCVReturnSuccess, let pixelBuffer else {
        throw RuntimeError("CVPixelBufferCreate NV12 failed: \(status)")
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

    guard CVPixelBufferGetPlaneCount(pixelBuffer) >= 2,
          let yBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0),
          let uvBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1) else {
        throw RuntimeError("NV12 pixel buffer has no planes")
    }

    let yStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
    let uvStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1)
    let frame = frameID & 0xff
    for y in 0..<height {
        let row = yBase.advanced(by: y * yStride).assumingMemoryBound(to: UInt8.self)
        for x in 0..<width {
            row[x] = UInt8((x + y + frame) & 0xff)
        }
    }
    for y in 0..<(height / 2) {
        let row = uvBase.advanced(by: y * uvStride).assumingMemoryBound(to: UInt8.self)
        for x in stride(from: 0, to: width, by: 2) {
            row[x] = UInt8(128 + ((frame / 4) % 24))
            row[x + 1] = UInt8(128 - ((frame / 4) % 24))
        }
    }

    let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
    return (pixelBuffer, Double(elapsed) / 1_000_000.0)
}

func codecType(_ codec: String) -> CMVideoCodecType {
    codec == "hevc" ? kCMVideoCodecType_HEVC : kCMVideoCodecType_H264
}

func encoderSpecification(options: Options) -> CFDictionary? {
    guard options.lowLatencyRateControl || !options.encoderID.isEmpty else { return nil }
    var spec: [String: Any] = [:]
    if options.lowLatencyRateControl {
        spec[kVTVideoEncoderSpecification_EnableLowLatencyRateControl as String] = true
    }
    if !options.encoderID.isEmpty {
        spec[kVTVideoEncoderSpecification_EncoderID as String] = options.encoderID
    }
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

    let keyAllowOpenGOP = "AllowOpenGOP" as CFString
    let keyMaxFrameDelayCount = "MaxFrameDelayCount" as CFString
    let keyPrioritizeSpeed = "PrioritizeEncodingSpeedOverQuality" as CFString

    try setProperty(kVTCompressionPropertyKey_RealTime, (options.realtime ? kCFBooleanTrue : kCFBooleanFalse) as Any)
    try setProperty(kVTCompressionPropertyKey_AllowFrameReordering, (options.allowFrameReordering ? kCFBooleanTrue : kCFBooleanFalse) as Any)
    try setProperty(kVTCompressionPropertyKey_AllowTemporalCompression, (options.allowTemporalCompression ? kCFBooleanTrue : kCFBooleanFalse) as Any, required: false)
    try setProperty(keyAllowOpenGOP, (options.allowOpenGOP ? kCFBooleanTrue : kCFBooleanFalse) as Any, required: false)
    if let maxFrameDelayCount = options.maxFrameDelayCount {
        try setProperty(keyMaxFrameDelayCount, maxFrameDelayCount, required: false)
    }
    if let prioritizeSpeed = options.prioritizeSpeed {
        try setProperty(keyPrioritizeSpeed, (prioritizeSpeed ? kCFBooleanTrue : kCFBooleanFalse) as Any, required: false)
    }
    try setProperty(kVTCompressionPropertyKey_ExpectedFrameRate, options.fps)
    try setProperty(kVTCompressionPropertyKey_MaxKeyFrameInterval, options.maxKeyFrameInterval)
    try setProperty(kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, options.maxKeyFrameIntervalDuration)
    try setProperty(kVTCompressionPropertyKey_AverageBitRate, bitrate)
    if options.dataRateLimitMbps > 0 {
        let bytesPerSecond = Int64(options.dataRateLimitMbps * 1_000_000 / 8)
        let limits = [NSNumber(value: bytesPerSecond), NSNumber(value: options.dataRateWindowSeconds)] as CFArray
        try setProperty(kVTCompressionPropertyKey_DataRateLimits, limits, required: false)
    }

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

func makeState(options: Options, onFrameFinished: ((EncodedFrame) -> Void)? = nil) throws -> EncoderState {
    let state = EncoderState(
        codec: options.codec,
        payloadFormat: options.payloadFormat,
        onFrameFinished: onFrameFinished
    )
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
    return state
}

func makeCompressionSession(options: Options, state: EncoderState) throws -> VTCompressionSession {
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

    try configure(session, options: options)
    if options.printSupportedProperties {
        printSupportedProperties(for: session)
    }
    return session
}

func encodePixelBuffer(
    _ pixelBuffer: CVPixelBuffer,
    frameID: Int,
    presentationFrameID: Int? = nil,
    generateMS: Double,
    frameDuration: CMTime,
    session: VTCompressionSession,
    state: EncoderState
) {
    state.markFrame(frameID, generateMS: generateMS)
    let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(presentationFrameID ?? frameID))
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
        return
    }
}

func printRunSummary(options: Options, state: EncoderState, frameCount: Int, submittedFrames: Int, skippedFrames: Int, label: String) throws {
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

    print("iBridge Primary encoder")
    print("run_label=\(label)")
    print("source=\(options.source)")
    print("resolution=\(options.width)x\(options.height)")
    print("target_fps=\(options.fps)")
    print("duration_seconds=\(options.durationSeconds)")
    print("codec=\(options.codec)")
    print("encoder_id=\(options.encoderID.isEmpty ? "auto" : options.encoderID)")
    print("bitrate_mbps=\(options.bitrateMbps > 0 ? options.bitrateMbps : 0)")
    print("data_rate_limit_mbps=\(options.dataRateLimitMbps)")
    print(String(format: "data_rate_window_seconds=%.3f", options.dataRateWindowSeconds))
    print("low_latency_rate_control=\(options.lowLatencyRateControl ? "on" : "off")")
    print("realtime=\(options.realtime ? "on" : "off")")
    print("allow_temporal_compression=\(options.allowTemporalCompression ? "on" : "off")")
    print("allow_frame_reordering=\(options.allowFrameReordering ? "on" : "off")")
    print("allow_open_gop=\(options.allowOpenGOP ? "on" : "off")")
    print("prioritize_speed=\(options.prioritizeSpeed.map { $0 ? "on" : "off" } ?? "unset")")
    print("max_frame_delay_count=\(options.maxFrameDelayCount.map(String.init) ?? "unset")")
    print("payload_format=\(options.payloadFormat)")
    print("static_change_every=\(options.staticChangeEvery)")
    print("max_keyframe_interval=\(options.maxKeyFrameInterval)")
    print(String(format: "max_keyframe_interval_duration=%.3f", options.maxKeyFrameIntervalDuration))
    print("sender_queue_depth=\(options.senderQueueDepth)")
    print("frames_requested=\(frameCount)")
    print("frames_submitted=\(submittedFrames)")
    print("frames_skipped=\(skippedFrames)")
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

struct TileLogicalFrame {
    let frameID: Int
    let completedTiles: Int
    let failedTiles: Int
    let groupLatencyMS: Double
    let maxTileEncodeLatencyMS: Double
    let payloadBytes: Int
}

final class TileFrameTracker {
    private let condition = NSCondition()
    private let tileCount: Int
    private var startNSByFrameID: [Int: UInt64] = [:]
    private var completedTilesByFrameID: [Int: Int] = [:]
    private var failedTilesByFrameID: [Int: Int] = [:]
    private var maxTileEncodeByFrameID: [Int: Double] = [:]
    private var payloadBytesByFrameID: [Int: Int] = [:]
    private var logicalFrames: [TileLogicalFrame] = []

    init(tileCount: Int) {
        self.tileCount = tileCount
    }

    func startFrame(_ logicalFrameID: Int) {
        condition.lock()
        startNSByFrameID[logicalFrameID] = DispatchTime.now().uptimeNanoseconds
        completedTilesByFrameID[logicalFrameID] = 0
        failedTilesByFrameID[logicalFrameID] = 0
        maxTileEncodeByFrameID[logicalFrameID] = 0
        payloadBytesByFrameID[logicalFrameID] = 0
        condition.unlock()
    }

    func finishTile(_ frame: EncodedFrame) {
        let logicalFrameID = frame.frameID / tileCount
        condition.lock()
        completedTilesByFrameID[logicalFrameID, default: 0] += 1
        if frame.status != noErr {
            failedTilesByFrameID[logicalFrameID, default: 0] += 1
        }
        maxTileEncodeByFrameID[logicalFrameID] = max(
            maxTileEncodeByFrameID[logicalFrameID, default: 0],
            frame.encodeLatencyMS
        )
        payloadBytesByFrameID[logicalFrameID, default: 0] += frame.payloadBytes

        let completedTiles = completedTilesByFrameID[logicalFrameID, default: 0]
        if completedTiles == tileCount, let startNS = startNSByFrameID[logicalFrameID] {
            let groupLatencyMS = Double(DispatchTime.now().uptimeNanoseconds - startNS) / 1_000_000.0
            logicalFrames.append(
                TileLogicalFrame(
                    frameID: logicalFrameID,
                    completedTiles: completedTiles,
                    failedTiles: failedTilesByFrameID[logicalFrameID, default: 0],
                    groupLatencyMS: groupLatencyMS,
                    maxTileEncodeLatencyMS: maxTileEncodeByFrameID[logicalFrameID, default: 0],
                    payloadBytes: payloadBytesByFrameID[logicalFrameID, default: 0]
                )
            )
            condition.broadcast()
        }
        condition.unlock()
    }

    func sortedLogicalFrames() -> [TileLogicalFrame] {
        condition.lock()
        let output = logicalFrames.sorted { $0.frameID < $1.frameID }
        condition.unlock()
        return output
    }

    func waitForFrame(_ logicalFrameID: Int, timeoutSeconds: TimeInterval = 10) -> Bool {
        condition.lock()
        defer { condition.unlock() }
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while !logicalFrames.contains(where: { $0.frameID == logicalFrameID }) {
            if !condition.wait(until: deadline) {
                return false
            }
        }
        return true
    }
}

func logicalCSVPath(for csvPath: String) -> String {
    guard !csvPath.isEmpty else { return "" }
    let url = URL(fileURLWithPath: csvPath)
    let base = url.deletingPathExtension().path
    return "\(base)_logical.csv"
}

func writeTileLogicalCSV(path: String, frames: [TileLogicalFrame]) throws {
    guard !path.isEmpty else { return }
    var output = "frame_id,completed_tiles,failed_tiles,group_latency_ms,max_tile_encode_latency_ms,payload_bytes\n"
    for frame in frames {
        output += "\(frame.frameID),\(frame.completedTiles),\(frame.failedTiles),"
        output += String(format: "%.4f,%.4f,", frame.groupLatencyMS, frame.maxTileEncodeLatencyMS)
        output += "\(frame.payloadBytes)\n"
    }
    try FileManager.default.createDirectory(
        atPath: URL(fileURLWithPath: path).deletingLastPathComponent().path,
        withIntermediateDirectories: true
    )
    try output.write(toFile: path, atomically: true, encoding: .utf8)
}

func printTiledRunSummary(
    options: Options,
    states: [EncoderState],
    tracker: TileFrameTracker,
    logicalFrameCount: Int,
    submittedFrames: Int,
    elapsedSeconds: Double
) throws {
    let tileFrames = states.flatMap { $0.sortedFrames() }.sorted { $0.frameID < $1.frameID }
    try writeCSV(path: options.csvPath, frames: tileFrames)

    let logicalFrames = tracker.sortedLogicalFrames()
    let logicalPath = logicalCSVPath(for: options.csvPath)
    try writeTileLogicalCSV(path: logicalPath, frames: logicalFrames)
    let steadyLogicalFrames = logicalFrames.filter { $0.frameID >= options.warmupFrames }

    let tileLatencies = tileFrames.map(\.encodeLatencyMS)
    let groupLatencies = logicalFrames.map(\.groupLatencyMS)
    let steadyGroupLatencies = steadyLogicalFrames.map(\.groupLatencyMS)
    let maxTileLatencies = logicalFrames.map(\.maxTileEncodeLatencyMS)
    let steadyMaxTileLatencies = steadyLogicalFrames.map(\.maxTileEncodeLatencyMS)
    let totalPayloadBytes = logicalFrames.reduce(0) { $0 + $1.payloadBytes }
    let failedLogicalFrames = logicalFrames.filter { $0.failedTiles > 0 }.count
    let failedTileFrames = tileFrames.filter { $0.status != noErr }.count
    let tileWidth = options.width / options.tileColumns
    let tileHeight = options.height / options.tileRows

    print("iBridge Primary encoder")
    print("run_label=synthetic-tiled")
    print("source=\(options.source)")
    print("resolution=\(options.width)x\(options.height)")
    print("tile_columns=\(options.tileColumns)")
    print("tile_rows=\(options.tileRows)")
    print("tile_resolution=\(tileWidth)x\(tileHeight)")
    print("tile_reuse_buffers=\(options.tileReuseBuffers ? "on" : "off")")
    print("tile_max_inflight_logical_frames=\(options.tileMaxInFlightLogicalFrames)")
    print("tile_reset_every_frames=\(options.tileResetEveryFrames)")
    print("warmup_frames=\(options.warmupFrames)")
    print("target_fps=\(options.fps)")
    print("duration_seconds=\(options.durationSeconds)")
    print("codec=\(options.codec)")
    print("encoder_id=\(options.encoderID.isEmpty ? "auto" : options.encoderID)")
    print("bitrate_mbps=\(options.bitrateMbps > 0 ? options.bitrateMbps : 0)")
    print("data_rate_limit_mbps=\(options.dataRateLimitMbps)")
    print(String(format: "data_rate_window_seconds=%.3f", options.dataRateWindowSeconds))
    print("low_latency_rate_control=\(options.lowLatencyRateControl ? "on" : "off")")
    print("realtime=\(options.realtime ? "on" : "off")")
    print("allow_temporal_compression=\(options.allowTemporalCompression ? "on" : "off")")
    print("allow_frame_reordering=\(options.allowFrameReordering ? "on" : "off")")
    print("allow_open_gop=\(options.allowOpenGOP ? "on" : "off")")
    print("prioritize_speed=\(options.prioritizeSpeed.map { $0 ? "on" : "off" } ?? "unset")")
    print("max_frame_delay_count=\(options.maxFrameDelayCount.map(String.init) ?? "unset")")
    print("payload_format=\(options.payloadFormat)")
    print("max_keyframe_interval=\(options.maxKeyFrameInterval)")
    print(String(format: "max_keyframe_interval_duration=%.3f", options.maxKeyFrameIntervalDuration))
    print("frames_requested=\(logicalFrameCount)")
    print("frames_submitted=\(submittedFrames)")
    print("frames_skipped=0")
    print("frames_encoded=\(logicalFrames.count)")
    print("failed_frames=\(failedLogicalFrames)")
    print("steady_frames_encoded=\(steadyLogicalFrames.count)")
    print(String(format: "elapsed_seconds=%.3f", elapsedSeconds))
    print(String(format: "effective_logical_fps=%.3f", Double(logicalFrames.count) / max(elapsedSeconds, 0.001)))
    print("tile_frames_requested=\(logicalFrameCount * options.tileColumns * options.tileRows)")
    print("tile_frames_encoded=\(tileFrames.count)")
    print("failed_tile_frames=\(failedTileFrames)")
    print(String(format: "avg_encode_latency_ms=%.3f", groupLatencies.reduce(0, +) / Double(max(groupLatencies.count, 1))))
    print(String(format: "p95_encode_latency_ms=%.3f", percentile(groupLatencies, 95)))
    print(String(format: "max_encode_latency_ms=%.3f", groupLatencies.max() ?? 0))
    print(String(format: "avg_steady_encode_latency_ms=%.3f", steadyGroupLatencies.reduce(0, +) / Double(max(steadyGroupLatencies.count, 1))))
    print(String(format: "p95_steady_encode_latency_ms=%.3f", percentile(steadyGroupLatencies, 95)))
    print(String(format: "max_steady_encode_latency_ms=%.3f", steadyGroupLatencies.max() ?? 0))
    print(String(format: "avg_tile_encode_latency_ms=%.3f", tileLatencies.reduce(0, +) / Double(max(tileLatencies.count, 1))))
    print(String(format: "p95_tile_encode_latency_ms=%.3f", percentile(tileLatencies, 95)))
    print(String(format: "avg_max_tile_encode_latency_ms=%.3f", maxTileLatencies.reduce(0, +) / Double(max(maxTileLatencies.count, 1))))
    print(String(format: "p95_max_tile_encode_latency_ms=%.3f", percentile(maxTileLatencies, 95)))
    print(String(format: "avg_steady_max_tile_encode_latency_ms=%.3f", steadyMaxTileLatencies.reduce(0, +) / Double(max(steadyMaxTileLatencies.count, 1))))
    print(String(format: "p95_steady_max_tile_encode_latency_ms=%.3f", percentile(steadyMaxTileLatencies, 95)))
    print("payload_bytes=\(totalPayloadBytes)")
    print("send_target=none")
    print("csv=\(options.csvPath.isEmpty ? "none" : options.csvPath)")
    print("logical_csv=\(logicalPath.isEmpty ? "none" : logicalPath)")
}

func runSyntheticTiled(options: Options) throws {
    let tileCount = options.tileColumns * options.tileRows
    let tileWidth = options.width / options.tileColumns
    let tileHeight = options.height / options.tileRows
    let tracker = TileFrameTracker(tileCount: tileCount)
    var tileOptions = options
    tileOptions.width = tileWidth
    tileOptions.height = tileHeight

    func makeTileStatesAndSessions() throws -> ([EncoderState], [VTCompressionSession]) {
        let states = try (0..<tileCount).map { _ in
            try makeState(options: tileOptions) { frame in
                tracker.finishTile(frame)
            }
        }
        let sessions = try states.map { try makeCompressionSession(options: tileOptions, state: $0) }
        return (states, sessions)
    }

    var (states, sessions) = try makeTileStatesAndSessions()
    var allStates = states
    defer {
        for session in sessions {
            VTCompressionSessionInvalidate(session)
        }
    }

    let logicalFrameCount = options.fps * options.durationSeconds
    let frameDuration = CMTime(value: 1, timescale: CMTimeScale(options.fps))
    let wallFrameDuration = 1.0 / Double(options.fps)
    let runStart = DispatchTime.now()
    var submittedFrames = 0
    var sessionStartLogicalFrameID = 0
    let reusablePixelBuffers: [(CVPixelBuffer, Double)] = options.tileReuseBuffers
        ? try (0..<tileCount).map { try makeNV12PixelBuffer(width: tileWidth, height: tileHeight, frameID: $0) }
        : []

    for logicalFrameID in 0..<logicalFrameCount {
        if options.tileResetEveryFrames > 0,
           logicalFrameID > 0,
           logicalFrameID % options.tileResetEveryFrames == 0 {
            for session in sessions {
                VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
                VTCompressionSessionInvalidate(session)
            }
            let replacement = try makeTileStatesAndSessions()
            states = replacement.0
            sessions = replacement.1
            allStates.append(contentsOf: states)
            sessionStartLogicalFrameID = logicalFrameID
        }

        if options.tileMaxInFlightLogicalFrames > 0 {
            let oldestAllowed = logicalFrameID - options.tileMaxInFlightLogicalFrames
            if oldestAllowed >= 0, !tracker.waitForFrame(oldestAllowed) {
                fputs("warning: timed out waiting for logical tile frame \(oldestAllowed)\n", stderr)
            }
        }

        if options.realtime {
            let target = Double(logicalFrameID) * wallFrameDuration
            let elapsed = Double(DispatchTime.now().uptimeNanoseconds - runStart.uptimeNanoseconds) / 1_000_000_000.0
            if target > elapsed {
                Thread.sleep(forTimeInterval: target - elapsed)
            }
        }

        tracker.startFrame(logicalFrameID)
        for tileIndex in 0..<tileCount {
            let tileFrameID = logicalFrameID * tileCount + tileIndex
            let (pixelBuffer, generateMS) = options.tileReuseBuffers
                ? reusablePixelBuffers[tileIndex]
                : try makeNV12PixelBuffer(width: tileWidth, height: tileHeight, frameID: tileFrameID)
            encodePixelBuffer(
                pixelBuffer,
                frameID: tileFrameID,
                presentationFrameID: logicalFrameID - sessionStartLogicalFrameID,
                generateMS: generateMS,
                frameDuration: frameDuration,
                session: sessions[tileIndex],
                state: states[tileIndex]
            )
        }
        submittedFrames += 1
    }

    for session in sessions {
        VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
    }
    let elapsedSeconds = Double(DispatchTime.now().uptimeNanoseconds - runStart.uptimeNanoseconds) / 1_000_000_000.0
    try printTiledRunSummary(
        options: options,
        states: allStates,
        tracker: tracker,
        logicalFrameCount: logicalFrameCount,
        submittedFrames: submittedFrames,
        elapsedSeconds: elapsedSeconds
    )
}

func runSynthetic(options: Options) throws {
    let state = try makeState(options: options)
    let session = try makeCompressionSession(options: options, state: state)
    defer { VTCompressionSessionInvalidate(session) }

    let frameCount = options.fps * options.durationSeconds
    let frameDuration = CMTime(value: 1, timescale: CMTimeScale(options.fps))
    let wallFrameDuration = 1.0 / Double(options.fps)
    let runStart = DispatchTime.now()
    var submittedFrames = 0
    var skippedFrames = 0

    for frameID in 0..<frameCount {
        if options.realtime {
            let target = Double(frameID) * wallFrameDuration
            let elapsed = Double(DispatchTime.now().uptimeNanoseconds - runStart.uptimeNanoseconds) / 1_000_000_000.0
            if target > elapsed {
                Thread.sleep(forTimeInterval: target - elapsed)
            }
        }

        if options.source == "synthetic-static-skip", frameID % options.staticChangeEvery != 0 {
            skippedFrames += 1
            continue
        }

        let (pixelBuffer, generateMS) = options.source == "synthetic-nv12"
            ? try makeNV12PixelBuffer(width: options.width, height: options.height, frameID: frameID)
            : try makeBGRAPixelBuffer(width: options.width, height: options.height, frameID: frameID)
        submittedFrames += 1
        encodePixelBuffer(
            pixelBuffer,
            frameID: frameID,
            generateMS: generateMS,
            frameDuration: frameDuration,
            session: session,
            state: state
        )
    }

    VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
    try printRunSummary(
        options: options,
        state: state,
        frameCount: frameCount,
        submittedFrames: submittedFrames,
        skippedFrames: skippedFrames,
        label: "synthetic"
    )
}

@available(macOS 14.0, *)
final class ScreenCaptureEncodeRunner: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    private let options: Options
    private let state: EncoderState
    private let session: VTCompressionSession
    private let frameDuration: CMTime
    private let frameCount: Int
    private let done = DispatchSemaphore(value: 0)
    private let stateQueue = DispatchQueue(label: "iBridgePrimary.ScreenCaptureState")
    private var stream: SCStream?
    private var frameID = 0
    private var submittedFrames = 0
    private var startError: Error?
    private var stopped = false

    init(options: Options, state: EncoderState, session: VTCompressionSession) {
        self.options = options
        self.state = state
        self.session = session
        self.frameDuration = CMTime(value: 1, timescale: CMTimeScale(options.fps))
        self.frameCount = options.fps * options.durationSeconds
    }

    func run() throws {
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(
                    false,
                    onScreenWindowsOnly: true
                )
                guard options.captureDisplayIndex < content.displays.count else {
                    throw RuntimeError("capture display index \(options.captureDisplayIndex) out of range; displays=\(content.displays.count)")
                }
                let display = content.displays[options.captureDisplayIndex]
                let filter = SCContentFilter(display: display, excludingWindows: [])
                let configuration = SCStreamConfiguration()
                configuration.width = options.width
                configuration.height = options.height
                configuration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(options.fps))
                configuration.queueDepth = options.captureQueueDepth
                configuration.pixelFormat = kCVPixelFormatType_32BGRA
                configuration.showsCursor = true
                configuration.capturesAudio = false

                let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
                self.stream = stream
                try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: DispatchQueue(label: "iBridgePrimary.ScreenCaptureOutput"))
                try await stream.startCapture()
                DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(self.options.durationSeconds)) { [weak self, weak stream] in
                    guard let self, let stream else { return }
                    self.requestStop(stream)
                }
            } catch {
                self.stateQueue.sync {
                    self.startError = error
                }
                self.done.signal()
            }
        }

        let timeout = DispatchTime.now() + .seconds(options.durationSeconds + 10)
        if done.wait(timeout: timeout) == .timedOut {
            stream?.stopCapture { _ in }
            throw RuntimeError("screen capture timed out")
        }
        let error = stateQueue.sync { startError }
        if let error {
            throw error
        }
    }

    func stream(_: SCStream, didStopWithError error: Error) {
        stateQueue.sync {
            if startError == nil {
                startError = error
            }
        }
        done.signal()
    }

    private func requestStop(_ stream: SCStream) {
        let shouldStop = stateQueue.sync { () -> Bool in
            if stopped {
                return false
            }
            stopped = true
            return true
        }
        guard shouldStop else { return }
        stream.stopCapture { _ in
            VTCompressionSessionCompleteFrames(self.session, untilPresentationTimeStamp: .invalid)
            self.done.signal()
        }
    }

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard outputType == .screen,
              sampleBuffer.isValid,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let nextFrame = stateQueue.sync { () -> (frameID: Int, shouldStop: Bool)? in
            if stopped || frameID >= frameCount {
                return nil
            }
            let currentFrameID = frameID
            frameID += 1
            submittedFrames += 1
            let shouldStop = frameID >= frameCount
            return (currentFrameID, shouldStop)
        }
        guard let nextFrame else {
            return
        }

        encodePixelBuffer(
            pixelBuffer,
            frameID: nextFrame.frameID,
            generateMS: 0,
            frameDuration: frameDuration,
            session: session,
            state: state
        )

        if nextFrame.shouldStop {
            requestStop(stream)
        }
    }

    func counts() -> (submitted: Int, skipped: Int) {
        stateQueue.sync {
            (submittedFrames, max(0, frameCount - submittedFrames))
        }
    }
}

func runScreenCapture(options: Options) throws {
    guard #available(macOS 14.0, *) else {
        throw RuntimeError("ScreenCaptureKit path requires macOS 14 or newer in this spike")
    }
    let state = try makeState(options: options)
    let session = try makeCompressionSession(options: options, state: state)
    defer { VTCompressionSessionInvalidate(session) }

    let runner = ScreenCaptureEncodeRunner(options: options, state: state, session: session)
    try runner.run()
    let counts = runner.counts()
    try printRunSummary(
        options: options,
        state: state,
        frameCount: options.fps * options.durationSeconds,
        submittedFrames: counts.submitted,
        skippedFrames: counts.skipped,
        label: "screen-capture"
    )
}

do {
    let options = try parseOptions(CommandLine.arguments)
    if options.listEncoders {
        try printVideoEncoderList()
    } else if options.source == "synthetic-nv12-tiled" {
        try runSyntheticTiled(options: options)
    } else if options.screenCapture {
        try runScreenCapture(options: options)
    } else {
        try runSynthetic(options: options)
    }
} catch {
    fputs("error: \(error)\n\n", stderr)
    usage()
    exit(1)
}
