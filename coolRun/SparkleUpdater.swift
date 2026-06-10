#if os(macOS)
import Foundation
#if canImport(Sparkle)
import Sparkle

@MainActor
final class SparkleUpdater {
    static let shared = SparkleUpdater()

    private let updaterController: SPUStandardUpdaterController

    private init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
#else
@MainActor
final class SparkleUpdater {
    static let shared = SparkleUpdater()

    private init() {}

    func checkForUpdates() {}
}
#endif
#endif
