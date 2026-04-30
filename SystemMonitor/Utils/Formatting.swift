import Foundation

enum Formatting {
    static func percentage(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }

    static func bytes(_ value: Double) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .binary)
    }

    static func throughput(_ value: Double) -> String {
        "\(bytes(value))/s"
    }
}
