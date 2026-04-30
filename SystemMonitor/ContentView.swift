import SwiftUI
import Charts

private enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case overview = "概览"
    case cpu = "CPU"
    case memory = "内存"
    case disk = "磁盘"
    case network = "网络"
    case battery = "电池与温度"
    case settings = "设置"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .disk: return "internaldrive"
        case .network: return "network"
        case .battery: return "battery.100"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: SystemMetricsViewModel
    @State private var selection: SidebarSection? = .overview


    @AppStorage("showMenuBar") private var showMenuBar = true

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(SidebarSection.allCases) { item in
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: item.icon)
                    }
                }
            }
            .navigationTitle("System Monitor")
            .listStyle(.sidebar)
        } detail: {
            detailView(for: selection ?? .overview)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(20)
                .background(Color(nsColor: .windowBackgroundColor))
        }
        .navigationSplitViewStyle(.balanced)
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private func detailView(for section: SidebarSection) -> some View {
        switch section {
        case .overview: overviewPage
        case .cpu: cpuPage
        case .memory: memoryPage
        case .disk: diskPage
        case .network: networkPage
        case .battery: batteryPage
        case .settings: settingsPage
        }
    }

    private var overviewPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("系统概览").font(.largeTitle.bold())
                HStack(spacing: 12) {
                    summaryCard("CPU 总负载", Formatting.percentage(viewModel.latest.cpu.totalUsage), "cpu")
                    summaryCard("内存压力", Formatting.percentage(viewModel.latest.memory.pressure), "memorychip")
                    summaryCard("磁盘读取", Formatting.throughput(viewModel.latest.disk.readBytesPerSecond), "arrow.down.doc")
                    summaryCard("网络上行", Formatting.throughput(viewModel.latest.network.uploadBytesPerSecond), "arrow.up.circle")
                }
                HStack(spacing: 16) {
                    chart(title: "CPU 历史", points: viewModel.cpuHistory, color: .green)
                    chart(title: "内存压力历史", points: viewModel.memoryHistory, color: .blue)
                }
                GroupBox("当前采样") {
                    VStack(spacing: 8) {
                        detailRow("更新时间", DateFormatter.localizedString(from: viewModel.latest.timestamp, dateStyle: .none, timeStyle: .medium))
                        detailRow("CPU 核心数", "\(viewModel.latest.cpu.coreUsages.count)")
                        detailRow("内存使用", "\(Formatting.bytes(Double(viewModel.latest.memory.usedBytes))) / \(Formatting.bytes(Double(viewModel.latest.memory.totalBytes)))")
                    }
                }
            }
        }
    }

    private var cpuPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("CPU 详情").font(.largeTitle.bold())
                GroupBox("总体") {
                    VStack(spacing: 8) {
                        detailRow("总使用率", Formatting.percentage(viewModel.latest.cpu.totalUsage))
                        detailRow("核心数", "\(viewModel.latest.cpu.coreUsages.count)")
                        detailRow("采样间隔", "1 秒")
                    }
                }
                chart(title: "CPU 使用率历史", points: viewModel.cpuHistory, color: .green)
                GroupBox("每核心") {
                    VStack(spacing: 10) {
                        ForEach(Array(viewModel.latest.cpu.coreUsages.enumerated()), id: \.offset) { idx, usage in
                            HStack {
                                Text("Core \(idx)").frame(width: 90, alignment: .leading)
                                ProgressView(value: usage)
                                Text(Formatting.percentage(usage)).font(.system(.body, design: .monospaced)).frame(width: 70, alignment: .trailing)
                            }
                        }
                    }
                }
            }
        }
    }

    private var memoryPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("内存详情").font(.largeTitle.bold())
            GroupBox("内存统计") {
                VStack(spacing: 8) {
                    detailRow("已用", Formatting.bytes(Double(viewModel.latest.memory.usedBytes)))
                    detailRow("总量", Formatting.bytes(Double(viewModel.latest.memory.totalBytes)))
                    detailRow("压力", Formatting.percentage(viewModel.latest.memory.pressure))
                    detailRow("可用估算", Formatting.bytes(Double(viewModel.latest.memory.totalBytes - viewModel.latest.memory.usedBytes)))
                }
            }
            chart(title: "内存压力历史", points: viewModel.memoryHistory, color: .blue)
            Spacer()
        }
    }

    private var diskPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("磁盘详情").font(.largeTitle.bold())
            GroupBox("实时 I/O") {
                VStack(spacing: 8) {
                    detailRow("读取速率", Formatting.throughput(viewModel.latest.disk.readBytesPerSecond))
                    detailRow("写入速率", Formatting.throughput(viewModel.latest.disk.writeBytesPerSecond))
                    detailRow("总吞吐", Formatting.throughput(viewModel.latest.disk.readBytesPerSecond + viewModel.latest.disk.writeBytesPerSecond))
                }
            }
            Spacer()
        }
    }

    private var networkPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("网络详情").font(.largeTitle.bold())
            GroupBox("实时流量") {
                VStack(spacing: 8) {
                    detailRow("下载", Formatting.throughput(viewModel.latest.network.downloadBytesPerSecond))
                    detailRow("上传", Formatting.throughput(viewModel.latest.network.uploadBytesPerSecond))
                    detailRow("总流量", Formatting.throughput(viewModel.latest.network.downloadBytesPerSecond + viewModel.latest.network.uploadBytesPerSecond))
                    detailRow("更新时间", DateFormatter.localizedString(from: viewModel.latest.timestamp, dateStyle: .none, timeStyle: .medium))
                }
            }
            Spacer()
        }
    }

    private var batteryPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("电池与温度详情").font(.largeTitle.bold())
            GroupBox("电池") {
                VStack(spacing: 8) {
                    detailRow("电量", viewModel.latest.battery.level.map { Formatting.percentage($0) } ?? "N/A")
                    detailRow("充电状态", viewModel.latest.battery.isCharging.map { $0 ? "充电中" : "未充电" } ?? "N/A")
                }
            }
            GroupBox("温度") {
                VStack(spacing: 8) {
                    detailRow("温度", viewModel.latest.temperature.celsius.map { String(format: "%.1f ℃", $0) } ?? "N/A")
                    Text("说明：部分 Mac 机型/权限环境无法直接读取温度，显示 N/A 属正常现象。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }


    private var settingsPage: some View {
        Form {
            Section("采样设置") {
                Slider(value: $viewModel.refreshInterval, in: 0.5...3.0, step: 0.5)
                Text("刷新间隔: \(String(format: "%.1f", viewModel.refreshInterval)) 秒")
                Stepper("历史点数: \(viewModel.historyLimit)", value: $viewModel.historyLimit, in: 30...600, step: 30)
            }
            Section("显示设置") {
                Toggle("显示菜单栏监视器", isOn: $showMenuBar)
            }
            Section("说明") {
                Text("磁盘 I/O 基于系统公开计数器估算，受系统版本影响可能存在偏差。")
                Text("温度数据在部分机型不可用时显示 N/A。")
            }
        }
        .frame(maxWidth: 560)
    }

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
            .frame(height: 230)
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
    }
}
