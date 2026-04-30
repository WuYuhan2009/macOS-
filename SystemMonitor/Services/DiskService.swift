import Foundation
import Darwin

final class DiskService {
    private var previousRead: UInt64 = 0
    private var previousWrite: UInt64 = 0
    private var previousTime: Date = Date()

    func read() -> DiskMetrics {
        let read = readUInt64(name: "kern.monotonicdiskreads") ?? previousRead
        let write = readUInt64(name: "kern.monotonicdiskwrites") ?? previousWrite
        let now = Date()
        let delta = now.timeIntervalSince(previousTime)
        defer {
            previousRead = read
            previousWrite = write
            previousTime = now
        }
        guard delta > 0 else {
            return DiskMetrics(readBytesPerSecond: 0, writeBytesPerSecond: 0)
        }

        return DiskMetrics(
            readBytesPerSecond: Double(read &- previousRead) / delta,
            writeBytesPerSecond: Double(write &- previousWrite) / delta
        )
    }

    private func readUInt64(name: String) -> UInt64? {
        var value = UInt64(0)
        var size = MemoryLayout<UInt64>.size
        let result = name.withCString { ptr in
            sysctlbyname(ptr, &value, &size, nil, 0)
        }
        return result == 0 ? value : nil
    }
}
