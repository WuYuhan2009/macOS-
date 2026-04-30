import SwiftUI

@main
struct SystemMonitorApp: App {
    @StateObject private var viewModel = SystemMetricsViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 1100, minHeight: 760)
        }
        .windowStyle(.automatic)
    }
}
