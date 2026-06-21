import SwiftUI

struct MenuBarMonitorView: View {
    @State private var viewModel = SystemMonitorViewModel()
    @State private var viewMode: ViewMode = .monitor
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // 视图切换标签
            viewModePicker

            // 内容区域
            switch viewMode {
            case .monitor:
                MonitorPanel(
                    snapshot: viewModel.snapshot,
                    cpuHistory: viewModel.cpuHistory,
                    memoryHistory: viewModel.memoryHistory,
                    downloadHistory: viewModel.downloadHistory,
                    uploadHistory: viewModel.uploadHistory,
                    cpuTempHistory: viewModel.cpuTempHistory,
                    gpuTempHistory: viewModel.gpuTempHistory
                )
            case .calendar:
                CalendarView()
            }
        }
        .frame(width: 220)
        .padding(8)
        .background {
            ZStack {
                VisualEffectBlur(material: colorScheme == .dark ? .hudWindow : .menu, blendingMode: .behindWindow)
                if colorScheme == .light {
                    Color.white.opacity(0.3)
                } else {
                    Color.black.opacity(0.2)
                }
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    // MARK: - 视图切换标签

    private var viewModePicker: some View {
        HStack(spacing: 0) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewMode = mode
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 10, weight: .medium))
                        Text(mode.displayName)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(viewMode == mode ? AppTheme.healthy : AppTheme.textSecondary(colorScheme))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        if viewMode == mode {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(AppTheme.healthy.opacity(0.15))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        }
        .padding(.bottom, 6)
    }
}
