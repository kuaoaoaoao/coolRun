import SwiftUI

struct MenuBarMonitorView: View {
    @State private var viewModel = SystemMonitorViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        MonitorPanel(
            snapshot: viewModel.snapshot,
            cpuHistory: viewModel.cpuHistory,
            memoryHistory: viewModel.memoryHistory,
            downloadHistory: viewModel.downloadHistory,
            uploadHistory: viewModel.uploadHistory,
            cpuTempHistory: viewModel.cpuTempHistory,
            gpuTempHistory: viewModel.gpuTempHistory
        )
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
}
