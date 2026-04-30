import Foundation

struct CPUMetrics {
    var totalUsage: Double
    var coreUsages: [Double]
}

struct MemoryMetrics {
    var usedBytes: UInt64
    var totalBytes: UInt64
    var pressure: Double
}

struct DiskMetrics {
    var readBytesPerSecond: Double
    var writeBytesPerSecond: Double
}

struct NetworkMetrics {
    var uploadBytesPerSecond: Double
    var downloadBytesPerSecond: Double
}

struct BatteryMetrics {
    var level: Double?
    var isCharging: Bool?
}

struct TemperatureMetrics {
    var celsius: Double?
}

struct SystemMetrics {
    var timestamp: Date
    var cpu: CPUMetrics
    var memory: MemoryMetrics
    var disk: DiskMetrics
    var network: NetworkMetrics
    var battery: BatteryMetrics
    var temperature: TemperatureMetrics
}

struct MetricPoint: Identifiable {
    let id = UUID()
    let time: Date
    let value: Double
}
