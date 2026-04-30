import SwiftUI

struct SettingsView: View {
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
