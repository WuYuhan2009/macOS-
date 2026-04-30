import Foundation
import Combine

final class SystemMetricsViewModel: ObservableObject {
    @Published var latest: SystemMetrics
    @Published var cpuHistory: [MetricPoint] = []
    @Published var memoryHistory: [MetricPoint] = []
    @Published var diskReadHistory: [MetricPoint] = []
    @Published var diskWriteHistory: [MetricPoint] = []
    @Published var netDownHistory: [MetricPoint] = []
    @Published var netUpHistory: [MetricPoint] = []

    private let cpuService = CPUService()
    private let memoryService = MemoryService()
    private let diskService = DiskService()
    private let networkService = NetworkService()
    private let batteryService = BatteryService()
    private var cancellable: AnyCancellable?

    @Published var refreshInterval: Double = 1.0 { didSet { start() } }
    @Published var historyLimit: Int = 120

    init() {
        latest = SystemMetrics(
            timestamp: Date(),
            cpu: CPUMetrics(totalUsage: 0, coreUsages: []),
            memory: MemoryMetrics(usedBytes: 0, totalBytes: ProcessInfo.processInfo.physicalMemory, pressure: 0),
            disk: DiskMetrics(readBytesPerSecond: 0, writeBytesPerSecond: 0),
            network: NetworkMetrics(uploadBytesPerSecond: 0, downloadBytesPerSecond: 0),
            battery: BatteryMetrics(level: nil, isCharging: nil),
            temperature: TemperatureMetrics(celsius: nil)
        )
        start()
    }

    func start() {
        cancellable?.cancel()
        cancellable = Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refresh() }
    }

    private func refresh() {
        let now = Date()
        let cpu = cpuService.read()
        let memory = memoryService.read()
        let disk = diskService.read()
        let network = networkService.read()

        latest = SystemMetrics(
            timestamp: now,
            cpu: cpu,
            memory: memory,
            disk: disk,
            network: network,
            battery: batteryService.readBattery(),
            temperature: batteryService.readTemperature()
        )

        cpuHistory.append(.init(time: now, value: cpu.totalUsage))
        memoryHistory.append(.init(time: now, value: memory.pressure))
        diskReadHistory.append(.init(time: now, value: disk.readBytesPerSecond))
        diskWriteHistory.append(.init(time: now, value: disk.writeBytesPerSecond))
        netDownHistory.append(.init(time: now, value: network.downloadBytesPerSecond))
        netUpHistory.append(.init(time: now, value: network.uploadBytesPerSecond))

        cpuHistory = Array(cpuHistory.suffix(historyLimit))
        memoryHistory = Array(memoryHistory.suffix(historyLimit))
        diskReadHistory = Array(diskReadHistory.suffix(historyLimit))
        diskWriteHistory = Array(diskWriteHistory.suffix(historyLimit))
        netDownHistory = Array(netDownHistory.suffix(historyLimit))
        netUpHistory = Array(netUpHistory.suffix(historyLimit))
    }
}
