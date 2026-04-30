import Foundation
import Darwin

final class NetworkService {
    private var previousIn: UInt64 = 0
    private var previousOut: UInt64 = 0
    private var previousTime: Date = Date()

    func read() -> NetworkMetrics {
        let (bytesIn, bytesOut) = interfaceBytes()
        let now = Date()
        let delta = now.timeIntervalSince(previousTime)
        defer {
            previousIn = bytesIn
            previousOut = bytesOut
            previousTime = now
        }

        guard delta > 0 else {
            return NetworkMetrics(uploadBytesPerSecond: 0, downloadBytesPerSecond: 0)
        }

        return NetworkMetrics(
            uploadBytesPerSecond: Double(bytesOut &- previousOut) / delta,
            downloadBytesPerSecond: Double(bytesIn &- previousIn) / delta
        )
    }

    private func interfaceBytes() -> (UInt64, UInt64) {
        var addressPointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addressPointer) == 0, let first = addressPointer else { return (0, 0) }
        defer { freeifaddrs(addressPointer) }

        var inTotal: UInt64 = 0
        var outTotal: UInt64 = 0

        for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let flags = Int32(pointer.pointee.ifa_flags)
            guard (flags & IFF_UP) != 0, (flags & IFF_LOOPBACK) == 0 else { continue }
            guard let data = pointer.pointee.ifa_data else { continue }
            let networkData = data.assumingMemoryBound(to: if_data.self).pointee
            inTotal += UInt64(networkData.ifi_ibytes)
            outTotal += UInt64(networkData.ifi_obytes)
        }

        return (inTotal, outTotal)
    }
}
