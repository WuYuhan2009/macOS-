import Foundation

enum Formatting {
    static func percentage(_ value: Double) -> String {
        let normalized = abs(value) < 0.000_001 ? 0 : value * 100
        return normalized == 0 ? "0" : String(format: "%.1f%%", normalized)
    }

    static func bytes(_ value: Double) -> String {
        let safe = abs(value) < 0.5 ? 0 : value
        return safe == 0 ? "0" : ByteCountFormatter.string(fromByteCount: Int64(safe), countStyle: .binary)
    }

    static func throughput(_ value: Double) -> String {
        let safe = abs(value) < 0.5 ? 0 : value
        return safe == 0 ? "0" : "\(bytes(safe))/s"
    }
}
