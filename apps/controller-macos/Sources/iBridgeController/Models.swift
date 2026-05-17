import Foundation
import SwiftUI

let repoRoot: URL = {
    let fileManager = FileManager.default

    if Bundle.main.bundleURL.pathExtension == "app" {
        return Bundle.main.resourceURL ?? Bundle.main.bundleURL.deletingLastPathComponent()
    }

    var candidate = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
    for _ in 0..<8 {
        if fileManager.fileExists(atPath: candidate.appendingPathComponent("scripts/start_ibridge_virtual_capture.sh").path) {
            return candidate
        }
        candidate.deleteLastPathComponent()
    }

    return URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
}()

struct ReceiverPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let receiverIP: String
    let discoveryHost: String
    let displayName: String
    let profile: String
    let resolution: String
    let bitrateMbps: String
    let duration: String
    let receiverScript: String
    let receiverKey: String
    let wakeMAC: String = ""
    let wakeBroadcast: String = "255.255.255.255"
}

struct ValueOption: Identifiable, Hashable {
    let id: String
    let title: String
    let value: String
}

struct ReceiverDevice: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var modelName: String
    var receiverIP: String
    var discoveryHost: String
    var receiverScript: String
    var receiverKey: String
    var wake: WakeConfig?
}

struct WakeConfig: Codable, Hashable {
    var macAddress: String
    var broadcastTargets: String
    var autoWake: Bool
}

struct SenderSessionConfig: Codable, Hashable {
    var receiverID: UUID
    var virtualDisplayName: String
    var resolution: String
    var bitrateMbps: Int
    var durationSeconds: Int
    var cursorModeID: String
    var profile: String
}

enum StudioTab: String, CaseIterable, Identifiable {
    case sender = "Sender"
    case receiver = "Receiver"
    case logs = "Logs"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .sender: "macbook.and.iphone"
        case .receiver: "display"
        case .logs: "list.bullet.rectangle"
        }
    }
}

let presets: [ReceiverPreset] = [
    ReceiverPreset(
        id: "imac-27-5k-2014",
        name: "iMac 27-inch 5K Late 2014",
        category: "Retina iMacs",
        receiverIP: "",
        discoveryHost: "",
        displayName: "iMac 27-inch 5K Late 2014",
        profile: "lan-60hz",
        resolution: "5120x2880",
        bitrateMbps: "280",
        duration: "600",
        receiverScript: "scripts/start_2015_imac_receiver_macos.sh",
        receiverKey: "$HOME/.ssh/id_ed25519"
    ),
    ReceiverPreset(
        id: "imac-21-4k-2015",
        name: "iMac 21.5-inch 4K Late 2015",
        category: "Retina iMacs",
        receiverIP: "",
        discoveryHost: "",
        displayName: "iMac 21.5-inch 4K Late 2015",
        profile: "imac4k-quality",
        resolution: "4096x2304",
        bitrateMbps: "220",
        duration: "600",
        receiverScript: "scripts/start_2017_imac_receiver_macos.sh",
        receiverKey: ""
    ),
    ReceiverPreset(
        id: "imac-27-5k-2015",
        name: "iMac 27-inch 5K Late 2015",
        category: "Retina iMacs",
        receiverIP: "",
        discoveryHost: "",
        displayName: "iMac 27-inch 5K Late 2015",
        profile: "lan-60hz",
        resolution: "5120x2880",
        bitrateMbps: "280",
        duration: "600",
        receiverScript: "scripts/start_2015_imac_receiver_macos.sh",
        receiverKey: "$HOME/.ssh/id_ed25519"
    ),
    ReceiverPreset(
        id: "imac-21-4k-2017",
        name: "iMac 21.5-inch 4K 2017",
        category: "Retina iMacs",
        receiverIP: "",
        discoveryHost: "",
        displayName: "iMac 21.5-inch 4K 2017",
        profile: "imac4k-quality",
        resolution: "4096x2304",
        bitrateMbps: "220",
        duration: "600",
        receiverScript: "scripts/start_2017_imac_receiver_macos.sh",
        receiverKey: ""
    ),
    ReceiverPreset(
        id: "imac-27-5k-2017",
        name: "iMac 27-inch 5K 2017",
        category: "Retina iMacs",
        receiverIP: "",
        discoveryHost: "",
        displayName: "iMac 27-inch 5K 2017",
        profile: "lan-60hz",
        resolution: "5120x2880",
        bitrateMbps: "280",
        duration: "600",
        receiverScript: "scripts/start_2015_imac_receiver_macos.sh",
        receiverKey: "$HOME/.ssh/id_ed25519"
    ),
    ReceiverPreset(
        id: "imac-21-4k-2019",
        name: "iMac 21.5-inch 4K 2019",
        category: "Retina iMacs",
        receiverIP: "",
        discoveryHost: "",
        displayName: "iMac 21.5-inch 4K 2019",
        profile: "imac4k-quality",
        resolution: "4096x2304",
        bitrateMbps: "220",
        duration: "600",
        receiverScript: "scripts/start_2017_imac_receiver_macos.sh",
        receiverKey: ""
    ),
    ReceiverPreset(
        id: "imac-27-5k-2019",
        name: "iMac 27-inch 5K 2019",
        category: "Retina iMacs",
        receiverIP: "",
        discoveryHost: "",
        displayName: "iMac 27-inch 5K 2019",
        profile: "lan-60hz",
        resolution: "5120x2880",
        bitrateMbps: "280",
        duration: "600",
        receiverScript: "scripts/start_2015_imac_receiver_macos.sh",
        receiverKey: "$HOME/.ssh/id_ed25519"
    ),
    ReceiverPreset(
        id: "imac-27-5k-2020",
        name: "iMac 27-inch 5K 2020",
        category: "Retina iMacs",
        receiverIP: "",
        discoveryHost: "",
        displayName: "iMac 27-inch 5K 2020",
        profile: "lan-60hz",
        resolution: "5120x2880",
        bitrateMbps: "280",
        duration: "600",
        receiverScript: "scripts/start_2015_imac_receiver_macos.sh",
        receiverKey: "$HOME/.ssh/id_ed25519"
    ),
    ReceiverPreset(
        id: "imac-pro-2017",
        name: "iMac Pro 27-inch 5K 2017",
        category: "Retina iMacs",
        receiverIP: "",
        discoveryHost: "",
        displayName: "iMac Pro 27-inch 5K 2017",
        profile: "lan-60hz",
        resolution: "5120x2880",
        bitrateMbps: "280",
        duration: "600",
        receiverScript: "scripts/start_2015_imac_receiver_macos.sh",
        receiverKey: "$HOME/.ssh/id_ed25519"
    ),
    ReceiverPreset(
        id: "imac-24-m1-2021",
        name: "iMac 24-inch 4.5K M1 2021",
        category: "Apple Silicon iMacs",
        receiverIP: "",
        discoveryHost: "",
        displayName: "iMac 24-inch 4.5K M1 2021",
        profile: "lan-60hz",
        resolution: "4480x2520",
        bitrateMbps: "220",
        duration: "600",
        receiverScript: "scripts/start_2015_imac_receiver_macos.sh",
        receiverKey: "$HOME/.ssh/id_ed25519"
    ),
    ReceiverPreset(
        id: "imac-24-m3-2023",
        name: "iMac 24-inch 4.5K M3 2023",
        category: "Apple Silicon iMacs",
        receiverIP: "",
        discoveryHost: "",
        displayName: "iMac 24-inch 4.5K M3 2023",
        profile: "lan-60hz",
        resolution: "4480x2520",
        bitrateMbps: "220",
        duration: "600",
        receiverScript: "scripts/start_2015_imac_receiver_macos.sh",
        receiverKey: "$HOME/.ssh/id_ed25519"
    ),
    ReceiverPreset(
        id: "imac-24-m4-2024",
        name: "iMac 24-inch 4.5K M4 2024",
        category: "Apple Silicon iMacs",
        receiverIP: "",
        discoveryHost: "",
        displayName: "iMac 24-inch 4.5K M4 2024",
        profile: "lan-60hz",
        resolution: "4480x2520",
        bitrateMbps: "220",
        duration: "600",
        receiverScript: "scripts/start_2015_imac_receiver_macos.sh",
        receiverKey: "$HOME/.ssh/id_ed25519"
    )
]

let presetCategoryOrder = ["Retina iMacs", "Apple Silicon iMacs"]

func presets(in category: String) -> [ReceiverPreset] {
    presets.filter { $0.category == category }
}

let signalOptions = [
    ValueOption(id: "5k", title: "5K Retina Quality", value: "5120x2880"),
    ValueOption(id: "4_5k", title: "4.5K Retina Quality", value: "4480x2520"),
    ValueOption(id: "imac4k", title: "iMac 4K Native", value: "4096x2304"),
    ValueOption(id: "uhd", title: "UHD Quality", value: "3840x2160"),
    ValueOption(id: "qhd", title: "1440p Smooth", value: "2560x1440"),
    ValueOption(id: "custom", title: "Custom", value: "")
]

let bitrateOptions = [
    ValueOption(id: "80", title: "80 Mbps Smooth", value: "80"),
    ValueOption(id: "160", title: "160 Mbps Quality", value: "160"),
    ValueOption(id: "220", title: "220 Mbps 4K Quality", value: "220"),
    ValueOption(id: "280", title: "280 Mbps 5K Quality", value: "280"),
    ValueOption(id: "custom", title: "Custom", value: "")
]

let durationOptions = [
    ValueOption(id: "10m", title: "10 min", value: "600"),
    ValueOption(id: "30m", title: "30 min", value: "1800"),
    ValueOption(id: "1h", title: "1 hour", value: "3600"),
    ValueOption(id: "custom", title: "Custom", value: "")
]

let cursorOptions = [
    ValueOption(id: "universal-control", title: "iBridge Cursor Overlay", value: "0"),
    ValueOption(id: "captured", title: "Show Captured Cursor", value: "1"),
    ValueOption(id: "hidden", title: "Hide Captured Cursor", value: "2")
]

@MainActor
final class DisplaySession: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var receiverIP: String
    @Published var discoveryHost: String
    @Published var displayName: String
    @Published var profile: String
    @Published var resolution: String
    @Published var bitrateMbps: String
    @Published var duration: String
    @Published var receiverScript: String
    @Published var receiverKey: String
    @Published var wakeMAC: String
    @Published var wakeBroadcast: String
    @Published var autoWake: Bool
    @Published var signalOptionID: String
    @Published var bitrateOptionID: String
    @Published var durationOptionID: String
    @Published var cursorModeID: String

    init(preset: ReceiverPreset) {
        name = preset.name
        receiverIP = resolvedReceiverIP(displayName: preset.displayName, receiverIP: preset.receiverIP)
        discoveryHost = preset.discoveryHost
        displayName = preset.displayName
        profile = preset.profile
        resolution = preset.resolution
        bitrateMbps = preset.bitrateMbps
        duration = preset.duration
        receiverScript = preset.receiverScript
        receiverKey = preset.receiverKey
        let resolvedWakeMAC = preset.wakeMAC.isEmpty ? defaultWakeMAC(displayName: preset.displayName) : preset.wakeMAC
        wakeMAC = resolvedWakeMAC
        wakeBroadcast = preset.wakeBroadcast == "255.255.255.255" ? defaultWakeBroadcast(displayName: preset.displayName) : preset.wakeBroadcast
        autoWake = !resolvedWakeMAC.isEmpty
        signalOptionID = signalOptions.first { $0.value == preset.resolution }?.id ?? "custom"
        bitrateOptionID = bitrateOptions.first { $0.value == preset.bitrateMbps }?.id ?? "custom"
        durationOptionID = durationOptions.first { $0.value == preset.duration }?.id ?? "custom"
        cursorModeID = "universal-control"
    }

    init(stored: StoredDisplaySession) {
        name = stored.name
        receiverIP = resolvedReceiverIP(displayName: stored.displayName, receiverIP: stored.receiverIP)
        discoveryHost = stored.discoveryHost ?? defaultDiscoveryHost(
            displayName: stored.displayName,
            receiverIP: stored.receiverIP,
            receiverScript: stored.receiverScript
        )
        displayName = stored.displayName
        profile = stored.profile
        resolution = stored.resolution
        bitrateMbps = stored.bitrateMbps
        duration = stored.duration
        receiverScript = stored.receiverScript
        receiverKey = stored.receiverKey
        let resolvedWakeMAC = stored.wakeMAC ?? defaultWakeMAC(displayName: stored.displayName)
        wakeMAC = resolvedWakeMAC
        wakeBroadcast = stored.wakeBroadcast ?? defaultWakeBroadcast(displayName: stored.displayName)
        autoWake = stored.autoWake ?? !resolvedWakeMAC.isEmpty
        signalOptionID = signalOptions.first { $0.value == stored.resolution }?.id ?? "custom"
        bitrateOptionID = bitrateOptions.first { $0.value == stored.bitrateMbps }?.id ?? "custom"
        durationOptionID = durationOptions.first { $0.value == stored.duration }?.id ?? "custom"
        cursorModeID = stored.cursorModeID ?? "universal-control"
    }

    func apply(_ preset: ReceiverPreset) {
        name = preset.name
        receiverIP = resolvedReceiverIP(displayName: preset.displayName, receiverIP: preset.receiverIP)
        discoveryHost = preset.discoveryHost
        displayName = preset.displayName
        profile = preset.profile
        receiverScript = preset.receiverScript
        receiverKey = preset.receiverKey
        wakeMAC = preset.wakeMAC.isEmpty ? defaultWakeMAC(displayName: preset.displayName) : preset.wakeMAC
        wakeBroadcast = preset.wakeBroadcast == "255.255.255.255" ? defaultWakeBroadcast(displayName: preset.displayName) : preset.wakeBroadcast
        autoWake = !wakeMAC.isEmpty
        setResolution(preset.resolution)
        setBitrate(preset.bitrateMbps)
        setDuration(preset.duration)
    }

    func setResolution(_ value: String) {
        resolution = value
        signalOptionID = signalOptions.first { $0.value == value }?.id ?? "custom"
    }

    func setBitrate(_ value: String) {
        bitrateMbps = value
        bitrateOptionID = bitrateOptions.first { $0.value == value }?.id ?? "custom"
    }

    func setDuration(_ value: String) {
        duration = value
        durationOptionID = durationOptions.first { $0.value == value }?.id ?? "custom"
    }

    func stored() -> StoredDisplaySession {
        StoredDisplaySession(
            name: name,
            receiverIP: receiverIP,
            discoveryHost: discoveryHost,
            displayName: displayName,
            profile: profile,
            resolution: resolution,
            bitrateMbps: bitrateMbps,
            duration: duration,
            receiverScript: receiverScript,
            receiverKey: receiverKey,
            cursorModeID: cursorModeID,
            wakeMAC: wakeMAC,
            wakeBroadcast: wakeBroadcast,
            autoWake: autoWake,
            receiverDevice: ReceiverDevice(
                id: id,
                name: name,
                modelName: displayName,
                receiverIP: receiverIP,
                discoveryHost: discoveryHost,
                receiverScript: receiverScript,
                receiverKey: receiverKey,
                wake: wakeMAC.isEmpty ? nil : WakeConfig(
                    macAddress: wakeMAC,
                    broadcastTargets: wakeBroadcast,
                    autoWake: autoWake
                )
            ),
            senderConfig: SenderSessionConfig(
                receiverID: id,
                virtualDisplayName: displayName,
                resolution: resolution,
                bitrateMbps: Int(bitrateMbps) ?? 0,
                durationSeconds: Int(duration) ?? 0,
                cursorModeID: cursorModeID,
                profile: profile
            )
        )
    }

    var captureShowCursor: String {
        cursorOptions.first { $0.id == cursorModeID }?.value ?? "0"
    }
}

struct StoredDisplaySession: Codable {
    let name: String
    let receiverIP: String
    let discoveryHost: String?
    let displayName: String
    let profile: String
    let resolution: String
    let bitrateMbps: String
    let duration: String
    let receiverScript: String
    let receiverKey: String
    let cursorModeID: String?
    let wakeMAC: String?
    let wakeBroadcast: String?
    let autoWake: Bool?
    let receiverDevice: ReceiverDevice?
    let senderConfig: SenderSessionConfig?
}

struct StoredControllerState: Codable {
    static let currentSchemaVersion = 2

    let schemaVersion: Int
    let selectedTab: String
    let receiverPort: String
    let receiverTitle: String
    let sessions: [StoredDisplaySession]

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        selectedTab: String,
        receiverPort: String,
        receiverTitle: String,
        sessions: [StoredDisplaySession]
    ) {
        self.schemaVersion = schemaVersion
        self.selectedTab = selectedTab
        self.receiverPort = receiverPort
        self.receiverTitle = receiverTitle
        self.sessions = sessions
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case selectedTab
        case receiverPort
        case receiverTitle
        case sessions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        selectedTab = try container.decode(String.self, forKey: .selectedTab)
        receiverPort = try container.decode(String.self, forKey: .receiverPort)
        receiverTitle = try container.decode(String.self, forKey: .receiverTitle)
        sessions = try container.decode([StoredDisplaySession].self, forKey: .sessions)
    }
}

private func defaultDiscoveryHost(displayName: String, receiverIP: String, receiverScript: String) -> String {
    return ""
}

private func resolvedReceiverIP(displayName: String, receiverIP: String) -> String {
    return receiverIP
}

private func defaultWakeMAC(displayName: String) -> String {
    return ""
}

private func defaultWakeBroadcast(displayName: String) -> String {
    return "255.255.255.255"
}
