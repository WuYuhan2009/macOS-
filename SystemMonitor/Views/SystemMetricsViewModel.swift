import Foundation
import Combine

final class SystemMetricsViewModel: ObservableObject {
    @Published var latest: SystemMetrics
    @Published var cpuHistory: [MetricPoint] = []
    @Published var memoryHistory: [MetricPoint] = []

    private let cpuService = CPUService()
    private let memoryService = MemoryService()
    private let diskService = DiskService()
    private let networkService = NetworkService()
    private let batteryService = BatteryService()
    private var cancellable: AnyCancellable?

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

    private func start() {
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }

    private func refresh() {
        let now = Date()
        let cpu = cpuService.read()
        let memory = memoryService.read()
        latest = SystemMetrics(
            timestamp: now,
            cpu: cpu,
            memory: memory,
            disk: diskService.read(),
            network: networkService.read(),
            battery: batteryService.readBattery(),
            temperature: batteryService.readTemperature()
        )

        cpuHistory.append(MetricPoint(time: now, value: cpu.totalUsage))
        memoryHistory.append(MetricPoint(time: now, value: memory.pressure))
        cpuHistory = Array(cpuHistory.suffix(60))
        memoryHistory = Array(memoryHistory.suffix(60))
    }
}
