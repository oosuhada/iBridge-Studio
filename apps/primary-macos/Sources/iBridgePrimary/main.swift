import CoreMedia
import CoreVideo
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
}

struct EncodedFrame {
    let frameID: Int
    let generateMS: Double
    let encodeLatencyMS: Double
    let payloadBytes: Int
    let status: OSStatus
}

final class EncoderState {
    private let lock = NSLock()
    private var startTimes: [Int: DispatchTime] = [:]
    private var generateTimes: [Int: Double] = [:]
    private(set) var frames: [EncodedFrame] = []

    func markFrame(_ frameID: Int, generateMS: Double) {
        lock.lock()
        startTimes[frameID] = .now()
        generateTimes[frameID] = generateMS
        lock.unlock()
    }

    func finishFrame(_ frameID: Int, status: OSStatus, sampleBuffer: CMSampleBuffer?) {
        let end = DispatchTime.now()
        lock.lock()
        let start = startTimes.removeValue(forKey: frameID) ?? end
        let generateMS = generateTimes.removeValue(forKey: frameID) ?? 0
        lock.unlock()

        let elapsedNS = end.uptimeNanoseconds - start.uptimeNanoseconds
        let payloadBytes = sampleBuffer.map { CMSampleBufferGetTotalSampleSize($0) } ?? 0
        let frame = EncodedFrame(
            frameID: frameID,
            generateMS: generateMS,
            encodeLatencyMS: Double(elapsedNS) / 1_000_000.0,
            payloadBytes: payloadBytes,
            status: status
        )

        lock.lock()
        frames.append(frame)
        lock.unlock()
    }

    func sortedFrames() -> [EncodedFrame] {
        lock.lock()
        let output = frames.sorted { $0.frameID < $1.frameID }
        lock.unlock()
        return output
    }
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
    ibridge-primary --synthetic --resolution 2560x1440 --fps 60 --duration 2 --codec h264 --csv diagnostics.csv [--no-realtime]
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
        } else if arg == "--no-realtime" {
            options.realtime = false
        } else {
            throw RuntimeError("unknown argument: \(arg)")
        }
        index += 1
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

func configure(_ session: VTCompressionSession, options: Options) throws {
    let bitrate = options.width * options.height * options.fps * 2
    let properties: [(CFString, Any)] = [
        (kVTCompressionPropertyKey_RealTime, kCFBooleanTrue as Any),
        (kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse as Any),
        (kVTCompressionPropertyKey_ExpectedFrameRate, options.fps),
        (kVTCompressionPropertyKey_MaxKeyFrameInterval, options.fps),
        (kVTCompressionPropertyKey_AverageBitRate, bitrate)
    ]

    for (key, value) in properties {
        let status = VTSessionSetProperty(session, key: key, value: value as CFTypeRef)
        guard status == noErr else {
            throw RuntimeError("VTSessionSetProperty \(key) failed: \(status)")
        }
    }

    let prepareStatus = VTCompressionSessionPrepareToEncodeFrames(session)
    guard prepareStatus == noErr else {
        throw RuntimeError("VTCompressionSessionPrepareToEncodeFrames failed: \(prepareStatus)")
    }
}

func writeCSV(path: String, frames: [EncodedFrame]) throws {
    guard !path.isEmpty else { return }
    var output = "frame_id,generate_ms,encode_latency_ms,payload_bytes,status\n"
    for frame in frames {
        output += "\(frame.frameID),"
        output += String(format: "%.4f,%.4f,", frame.generateMS, frame.encodeLatencyMS)
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
    var session: VTCompressionSession?
    let createStatus = VTCompressionSessionCreate(
        allocator: kCFAllocatorDefault,
        width: Int32(options.width),
        height: Int32(options.height),
        codecType: codecType(options.codec),
        encoderSpecification: nil,
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

    let frames = state.sortedFrames()
    try writeCSV(path: options.csvPath, frames: frames)

    let latencies = frames.map(\.encodeLatencyMS)
    let generateTimes = frames.map(\.generateMS)
    let totalBytes = frames.reduce(0) { $0 + $1.payloadBytes }
    let failed = frames.filter { $0.status != noErr }.count

    print("iBridge Primary synthetic encoder")
    print("resolution=\(options.width)x\(options.height)")
    print("target_fps=\(options.fps)")
    print("duration_seconds=\(options.durationSeconds)")
    print("codec=\(options.codec)")
    print("frames_requested=\(frameCount)")
    print("frames_encoded=\(frames.count)")
    print("failed_frames=\(failed)")
    print(String(format: "avg_generate_ms=%.3f", generateTimes.reduce(0, +) / Double(max(generateTimes.count, 1))))
    print(String(format: "avg_encode_latency_ms=%.3f", latencies.reduce(0, +) / Double(max(latencies.count, 1))))
    print(String(format: "p95_encode_latency_ms=%.3f", percentile(latencies, 95)))
    print(String(format: "max_encode_latency_ms=%.3f", latencies.max() ?? 0))
    print("payload_bytes=\(totalBytes)")
    print("csv=\(options.csvPath.isEmpty ? "none" : options.csvPath)")
}

do {
    let options = try parseOptions(CommandLine.arguments)
    try runSynthetic(options: options)
} catch {
    fputs("error: \(error)\n\n", stderr)
    usage()
    exit(1)
}
