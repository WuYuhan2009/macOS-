import SwiftUI
import Charts

private enum SidebarSection: String, CaseIterable, Identifiable {
    case overview = "概览"
    case cpu = "CPU"
    case memory = "内存"
    case disk = "磁盘"
    case network = "网络"
    case battery = "电池与温度"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .disk: return "internaldrive"
        case .network: return "network"
        case .battery: return "battery.100"
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: SystemMetricsViewModel
    @State private var selection: SidebarSection? = .overview

    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
            }
            .navigationTitle("System Monitor")
            .listStyle(.sidebar)
        } detail: {
            Group {
                switch selection ?? .overview {
                case .overview: overviewPage
                case .cpu: cpuPage
                case .memory: memoryPage
                case .disk: diskPage
                case .network: networkPage
                case .battery: batteryPage
                }
            }
            .padding(20)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .preferredColorScheme(.light)
    }

    private var overviewPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("系统概览").font(.largeTitle.bold())
            HStack(spacing: 12) {
                summaryCard("CPU 总负载", Formatting.percentage(viewModel.latest.cpu.totalUsage), "cpu")
                summaryCard("内存压力", Formatting.percentage(viewModel.latest.memory.pressure), "memorychip")
                summaryCard("网络下行", Formatting.throughput(viewModel.latest.network.downloadBytesPerSecond), "arrow.down.circle")
                summaryCard("磁盘写入", Formatting.throughput(viewModel.latest.disk.writeBytesPerSecond), "externaldrive")
            }
            HStack(spacing: 16) { cpuChart; memoryChart }
            Spacer()
        }
    }

    private var cpuPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("CPU").font(.largeTitle.bold())
                Text("总使用率：\(Formatting.percentage(viewModel.latest.cpu.totalUsage))")
                cpuChart
                VStack(alignment: .leading, spacing: 8) {
                    Text("每核心详情").font(.headline)
                    ForEach(Array(viewModel.latest.cpu.coreUsages.enumerated()), id: \.offset) { idx, usage in
                        HStack {
                            Text("Core \(idx)").frame(width: 70, alignment: .leading)
                            ProgressView(value: usage)
                            Text(Formatting.percentage(usage)).font(.system(.body, design: .monospaced))
                        }
                    }
                }
            }
        }
    }

    private var memoryPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("内存").font(.largeTitle.bold())
            Text("已用：\(Formatting.bytes(Double(viewModel.latest.memory.usedBytes)))")
            Text("总量：\(Formatting.bytes(Double(viewModel.latest.memory.totalBytes)))")
            Text("压力：\(Formatting.percentage(viewModel.latest.memory.pressure))")
            memoryChart
            Spacer()
        }
    }

    private var diskPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("磁盘").font(.largeTitle.bold())
            detailRow("读取速率", Formatting.throughput(viewModel.latest.disk.readBytesPerSecond))
            detailRow("写入速率", Formatting.throughput(viewModel.latest.disk.writeBytesPerSecond))
            detailRow("采样频率", "1 秒")
            Spacer()
        }
    }

    private var networkPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("网络").font(.largeTitle.bold())
            detailRow("下载速率", Formatting.throughput(viewModel.latest.network.downloadBytesPerSecond))
            detailRow("上传速率", Formatting.throughput(viewModel.latest.network.uploadBytesPerSecond))
            detailRow("刷新时间", DateFormatter.localizedString(from: viewModel.latest.timestamp, dateStyle: .none, timeStyle: .medium))
            Spacer()
        }
    }

    private var batteryPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("电池与温度").font(.largeTitle.bold())
            detailRow("电量", viewModel.latest.battery.level.map { Formatting.percentage($0) } ?? "N/A")
            detailRow("充电状态", viewModel.latest.battery.isCharging.map { $0 ? "充电中" : "未充电" } ?? "N/A")
            detailRow("温度", viewModel.latest.temperature.celsius.map { String(format: "%.1f ℃", $0) } ?? "N/A")
            Spacer()
        }
    }

    private var cpuChart: some View { chart(title: "CPU 历史", points: viewModel.cpuHistory, color: .green) }
    private var memoryChart: some View { chart(title: "内存压力历史", points: viewModel.memoryHistory, color: .blue) }

    private func chart(title: String, points: [MetricPoint], color: Color) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline)
            Chart {
                ForEach(points) { point in
                    LineMark(x: .value("Time", point.time), y: .value("Value", point.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(color)
                }
            }
            .chartYScale(domain: 0...1)
            .frame(height: 240)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    private func summaryCard(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon).foregroundStyle(.secondary)
            Text(value).font(.title3.bold())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.system(.body, design: .monospaced))
        }
        .padding(.vertical, 4)
    }
}
