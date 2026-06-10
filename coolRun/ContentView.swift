import SwiftUI

struct ContentView: View {
    @State private var viewModel = SystemMonitorViewModel()

    var body: some View {
        MonitorPanel(snapshot: viewModel.snapshot)
            .padding(10)
            .background(AppTheme.background)
            .onAppear { viewModel.start() }
            .onDisappear { viewModel.stop() }
    }
}

struct MonitorPanel: View {
    let snapshot: SystemSnapshot

    var body: some View {
        VStack(spacing: 0) {
            CPUSection(metrics: snapshot.cpu)
            Separator()
            MemorySection(metrics: snapshot.memory)
            Separator()
            StorageSection(metrics: snapshot.storage)
            Separator()
            BatterySection(metrics: snapshot.battery)
            Separator()
            NetworkSection(metrics: snapshot.network)
        }
        .padding(.vertical, 10)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 5, y: 2)
    }
}

private struct CPUSection: View {
    let metrics: CPUMetrics

    var body: some View {
        MetricSection(icon: "cpu", title: "CPU", value: metrics.usage.percentText) {
            MetricRow(label: "核心", value: "\(metrics.coreCount)")
            MetricRow(label: "占用", value: metrics.usage.percentText)
            MiniBar(value: metrics.usage, tint: .blue)
                .padding(.top, 3)
        }
    }
}

private struct MemorySection: View {
    let metrics: MemoryMetrics

    var body: some View {
        MetricSection(icon: "memorychip", title: "内存", value: metrics.usage.percentText) {
            MetricRow(label: "已用", value: metrics.used.memoryText)
            MetricRow(label: "总量", value: metrics.total.memoryText)
            MetricRow(label: "压力", value: memoryPressureText)
        }
    }

    private var memoryPressureText: String {
        switch metrics.usage {
        case 0..<0.6:
            "轻"
        case 0..<0.82:
            "中"
        default:
            "高"
        }
    }
}

private struct StorageSection: View {
    let metrics: StorageMetrics

    var body: some View {
        MetricSection(icon: "externaldrive", title: "储存", value: "\(metrics.usage.percentText) 已使用") {
            MetricRow(label: "已用", value: metrics.used.storageText)
            MetricRow(label: "可用", value: metrics.available.storageText)
            ProgressPill(value: metrics.usage, tint: .blue)
                .padding(.top, 4)
        }
    }
}

private struct BatterySection: View {
    let metrics: BatteryMetrics

    var body: some View {
        MetricSection(icon: batteryIcon, title: "电池", value: levelText) {
            MetricRow(label: "状态", value: metrics.state.rawValue)
            MetricRow(label: "低电量模式", value: metrics.isLowPowerModeEnabled ? "开启" : "关闭")
        }
    }

    private var levelText: String {
        guard let level = metrics.level else { return "--" }
        return level.percentText
    }

    private var batteryIcon: String {
        switch metrics.state {
        case .charging:
            "battery.100.bolt"
        case .full:
            "battery.100"
        case .unplugged:
            "battery.50"
        case .noBattery, .unknown:
            "battery.0"
        }
    }
}

private struct NetworkSection: View {
    let metrics: NetworkMetrics

    var body: some View {
        MetricSection(icon: "network", title: "网络", value: networkName) {
            MetricRow(label: "本地 IP", value: localAddressText)
            MetricRow(label: "接口", value: metrics.activeInterfaceCount > 0 ? "\(metrics.activeInterfaceCount) 个活动接口" : "--")
        }
    }

    private var networkName: String {
        metrics.activeInterfaceCount > 0 ? "已连接" : "未连接"
    }

    private var localAddressText: String {
        metrics.primaryAddress ?? "--"
    }
}

private struct MetricSection<Content: View>: View {
    let icon: String
    let title: String
    let value: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 25, weight: .regular))
                .foregroundStyle(AppTheme.icon)
                .frame(width: 42)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(title):")
                        .foregroundStyle(.secondary)
                    Text(value)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .font(.system(size: 16, weight: .medium))

                content
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

private struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Text("\(label):")
                .foregroundStyle(.secondary)
            Text(value)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 0)
        }
        .font(.system(size: 12, weight: .regular))
    }
}

private struct Separator: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.separator)
            .frame(height: 1)
            .padding(.horizontal, 14)
    }
}

private struct MiniBar: View {
    let value: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let width = proxy.size.width
                let height = proxy.size.height
                let columns = 28

                for index in 0..<columns {
                    let phase = Double(index) / Double(columns)
                    let dynamic = 0.28 + abs(sin((phase + value) * .pi * 2.2)) * 0.72
                    let barHeight = max(2, height * dynamic * max(0.2, value))
                    let x = width * Double(index) / Double(columns)
                    path.addRect(CGRect(
                        x: x,
                        y: height - barHeight,
                        width: max(2, width / Double(columns) - 2),
                        height: barHeight
                    ))
                }
            }
            .fill(tint)
        }
        .frame(height: 19)
    }
}

private struct ProgressPill: View {
    let value: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color(nsColor: .separatorColor).opacity(0.28))
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(tint)
                    .frame(width: max(4, proxy.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: 10)
    }
}

enum AppTheme {
    static let background = Color(nsColor: .windowBackgroundColor)
    static let panel = Color(nsColor: .controlBackgroundColor)
    static let border = Color(nsColor: .separatorColor).opacity(0.8)
    static let separator = Color(nsColor: .separatorColor).opacity(0.7)
    static let icon = Color(nsColor: .secondaryLabelColor)
}

private extension Double {
    var percentText: String {
        (self * 100).formatted(.number.precision(.fractionLength(1))) + "%"
    }
}

private extension UInt64 {
    var memoryText: String {
        ByteCountFormatter.memoryFormatter.string(fromByteCount: Int64(self))
    }

    var storageText: String {
        ByteCountFormatter.storageFormatter.string(fromByteCount: Int64(self))
    }
}

private extension ByteCountFormatter {
    static let memoryFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .memory
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    static let storageFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(width: 224, height: 388)
    }
}
