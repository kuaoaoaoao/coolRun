import SwiftUI

struct MenuBarMonitorView: View {
    @State private var viewModel = SystemMonitorViewModel()

    var body: some View {
        MonitorPanel(snapshot: viewModel.snapshot)
            .frame(width: 224)
            .padding(10)
            .background(AppTheme.background)
            .onAppear { viewModel.start() }
            .onDisappear { viewModel.stop() }
    }
}
