import SwiftUI

@main
struct SystemMonitorApp: App {
    @StateObject private var viewModel = SystemMetricsViewModel()
    @AppStorage("showMenuBar") private var showMenuBar = true

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 1180, minHeight: 780)
        }

        Settings {
            SettingsPanel(viewModel: viewModel)
        }

        if showMenuBar {
            MenuBarExtra {
                VStack(alignment: .leading, spacing: 8) {
                    Label("CPU: \(Formatting.percentage(viewModel.latest.cpu.totalUsage))", systemImage: "cpu")
                    Label("内存: \(Formatting.percentage(viewModel.latest.memory.pressure))", systemImage: "memorychip")
                    Label("磁盘读: \(Formatting.throughput(viewModel.latest.disk.readBytesPerSecond))", systemImage: "arrow.down.doc")
                    Label("网络下行: \(Formatting.throughput(viewModel.latest.network.downloadBytesPerSecond))", systemImage: "arrow.down.circle")
                    Divider()
                    Text("更新时间: \(DateFormatter.localizedString(from: viewModel.latest.timestamp, dateStyle: .none, timeStyle: .medium))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(width: 300)
            } label: {
                Label("SystemMonitor", systemImage: "waveform.path.ecg")
            }
        }
    }
}

private struct SettingsPanel: View {
    @ObservedObject var viewModel: SystemMetricsViewModel
    @AppStorage("showMenuBar") private var showMenuBar = true

    var body: some View {
        Form {
            Section("刷新") {
                Slider(value: $viewModel.refreshInterval, in: 0.5...3.0, step: 0.5)
                Text("刷新间隔: \(String(format: "%.1f", viewModel.refreshInterval)) 秒")
                Stepper("历史长度: \(viewModel.historyLimit) 点", value: $viewModel.historyLimit, in: 30...600, step: 30)
            }
            Section("显示") {
                Toggle("显示菜单栏监视器", isOn: $showMenuBar)
            }
        }
        .padding()
        .frame(width: 420)
    }
}
