import SwiftUI
import Charts

struct ContentView: View {
    @ObservedObject var viewModel: SystemMetricsViewModel

    var body: some View {
        VStack(spacing: 16) {
            summary
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("CPU 历史").font(.headline)
                    Chart {
                        ForEach(viewModel.cpuHistory) { point in
                            LineMark(
                                x: .value("Time", point.time),
                                y: .value("Value", point.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.green)
                        }
                    }
                    .chartYScale(domain: 0...1)
                    .frame(height: 220)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading) {
                    Text("内存压力历史").font(.headline)
                    Chart {
                        ForEach(viewModel.memoryHistory) { point in
                            LineMark(
                                x: .value("Time", point.time),
                                y: .value("Value", point.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.blue)
                        }
                    }
                    .chartYScale(domain: 0...1)
                    .frame(height: 220)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            metrics
        }
        .padding()
        .preferredColorScheme(.dark)
    }

    private var summary: some View {
        HStack(spacing: 24) {
            Label("CPU \(Formatting.percentage(viewModel.latest.cpu.totalUsage))", systemImage: "cpu")
            Label("内存 \(Formatting.bytes(Double(viewModel.latest.memory.usedBytes))) / \(Formatting.bytes(Double(viewModel.latest.memory.totalBytes)))", systemImage: "memorychip")
            Label("网络下行 \(Formatting.throughput(viewModel.latest.network.downloadBytesPerSecond))", systemImage: "arrow.down.circle")
        }
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metrics: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CPU 每核心")
                .font(.headline)
            Text(viewModel.latest.cpu.coreUsages.enumerated().map { "\($0.offset): \(Formatting.percentage($0.element))" }.joined(separator: "  "))
                .font(.system(.body, design: .monospaced))
            Divider()
            HStack {
                Text("磁盘读: \(Formatting.throughput(viewModel.latest.disk.readBytesPerSecond))")
                Text("磁盘写: \(Formatting.throughput(viewModel.latest.disk.writeBytesPerSecond))")
                Text("上行: \(Formatting.throughput(viewModel.latest.network.uploadBytesPerSecond))")
                Text("电池: \(viewModel.latest.battery.level.map { Formatting.percentage($0) } ?? "N/A")")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
