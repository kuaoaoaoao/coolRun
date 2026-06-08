import Foundation
import Observation

@MainActor
@Observable
final class SystemMonitorViewModel {
    var snapshot = SystemSnapshot()

    private let sampler = SystemSampler()
    private var refreshTask: Task<Void, Never>?

    init() {
        refresh()
        start()
    }

    func start() {
        guard refreshTask == nil else { return }

        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.refresh()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh() {
        snapshot = sampler.sample()
    }
}
