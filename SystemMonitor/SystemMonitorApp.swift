import SwiftUI
import Charts

@main
struct SystemMonitorApp: App {
    @StateObject private var viewModel = SystemMetricsViewModel()
    @AppStorage("showMenuBar") private var showMenuBar = true
    @AppStorage("menuBarCompact") private var menuBarCompact = false

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 1180, minHeight: 780)
        }

        Settings {
            SettingsPanel(viewModel: viewModel)
        }

        MenuBarExtra("SystemMonitor", systemImage: "waveform.path.ecg") {
            if showMenuBar {
                VStack(alignment: .leading, spacing: 8) {
                    Label("CPU: \(Formatting.percentage(viewModel.latest.cpu.totalUsage))", systemImage: "cpu")
                    Label("内存: \(Formatting.percentage(viewModel.latest.memory.pressure))", systemImage: "memorychip")
                    if !menuBarCompact {
                        Chart {
                            ForEach(viewModel.cpuHistory.suffix(30)) { point in
                                LineMark(x: .value("t", point.time), y: .value("CPU", point.value))
                                    .foregroundStyle(.green)
                            }
                            ForEach(viewModel.memoryHistory.suffix(30)) { point in
                                LineMark(x: .value("t", point.time), y: .value("MEM", point.value))
                                    .foregroundStyle(.blue)
                            }
                        }
                        .chartYScale(domain: 0...1)
                        .frame(height: 90)
                    }
                    Label("磁盘读: \(Formatting.throughput(viewModel.latest.disk.readBytesPerSecond))", systemImage: "arrow.down.doc")
                    Label("网络下行: \(Formatting.throughput(viewModel.latest.network.downloadBytesPerSecond))", systemImage: "arrow.down.circle")
                }
                .padding(10)
                .frame(width: menuBarCompact ? 260 : 320)
            } else {
                Text("菜单栏监视器已关闭")
                    .padding(10)
            }
        }
    }
}

private struct SettingsPanel: View {
    @ObservedObject var viewModel: SystemMetricsViewModel
    @AppStorage("showMenuBar") private var showMenuBar = true
    @AppStorage("menuBarCompact") private var menuBarCompact = false
    @AppStorage("showCPUChart") private var showCPUChart = true
    @AppStorage("showMemoryChart") private var showMemoryChart = true
    @AppStorage("showDiskDetails") private var showDiskDetails = true
    @AppStorage("showNetworkDetails") private var showNetworkDetails = true
    @AppStorage("professionalMode") private var professionalMode = true

    var body: some View {
        Form {
            Section("刷新") {
                Slider(value: $viewModel.refreshInterval, in: 0.25...5.0, step: 0.25)
                Text("刷新间隔: \(String(format: "%.2f", viewModel.refreshInterval)) 秒")
                Stepper("历史长度: \(viewModel.historyLimit) 点", value: $viewModel.historyLimit, in: 30...1200, step: 30)
            }
            Section("菜单栏") {
                Toggle("显示菜单栏监视器详情", isOn: $showMenuBar)
                Toggle("紧凑模式", isOn: $menuBarCompact)
            }
            Section("显示模块") {
                Toggle("显示 CPU 图", isOn: $showCPUChart)
                Toggle("显示内存图", isOn: $showMemoryChart)
                Toggle("显示磁盘高级信息", isOn: $showDiskDetails)
                Toggle("显示网络高级信息", isOn: $showNetworkDetails)
                Toggle("专业模式（显示更多字段）", isOn: $professionalMode)
            }
        }
        .padding()
        .frame(width: 460)
    }
}
