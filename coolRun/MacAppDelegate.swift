#if os(macOS)
import AppKit
import SwiftUI

@MainActor
final class MacAppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private let viewModel = SystemMonitorViewModel()
    private let goldPriceService = GoldPriceService()
    private var settingsWindow: NSWindow?
    private var iconTimer: Timer?
    private var goldPriceTask: Task<Void, Never>?
    private var coinPhase = 0.0
    private var goldPriceText = "金价 --"
    private let goldPriceRefreshInterval: Duration = .seconds(1)
    private let iconFramesPerSecond = 30.0

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem

        if let button = statusItem.button {
            button.imagePosition = .imageLeft
            button.image = CoinIconRenderer.image(phase: coinPhase)
            button.title = " \(goldPriceText)"
            button.action = #selector(handleStatusItemClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover.behavior = .transient
        popover.animates = false
        popover.contentSize = NSSize(width: 244, height: 408)
        popover.contentViewController = NSHostingController(rootView: MenuBarMonitorView())

        viewModel.start()
        startIconAnimation()
        startGoldPriceUpdates()
    }

    func applicationWillTerminate(_ notification: Notification) {
        iconTimer?.invalidate()
        goldPriceTask?.cancel()
        viewModel.stop()
    }

    @objc private func handleStatusItemClick() {
        switch NSApp.currentEvent?.type {
        case .rightMouseUp, .rightMouseDown:
            showContextMenu()
        default:
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func showContextMenu() {
        guard let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        }

        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "设置", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出程序", action: #selector(quitApplication), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 2), in: button)
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        let didOpenSettings = NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        if !didOpenSettings {
            showFallbackSettingsWindow()
        }
    }

    @objc private func quitApplication() {
        NSApp.terminate(nil)
    }

    private func showFallbackSettingsWindow() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 452, height: 332),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "coolRun 设置"
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: SettingsView())
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    private func startIconAnimation() {
        iconTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 1 / iconFramesPerSecond, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshIcon()
            }
        }
        timer.tolerance = 0.01
        iconTimer = timer
    }

    @MainActor
    private func refreshIcon() {
        let cpuUsage = min(max(viewModel.snapshot.cpu.usage, 0), 1)
        let revolutionsPerSecond = 0.35 + cpuUsage * 2.15
        coinPhase = (coinPhase + (.pi * 2 * revolutionsPerSecond / iconFramesPerSecond))
            .truncatingRemainder(dividingBy: .pi * 2)

        statusItem?.button?.image = CoinIconRenderer.image(phase: coinPhase)
        statusItem?.button?.title = " \(goldPriceText)"
    }

    private func startGoldPriceUpdates() {
        goldPriceTask?.cancel()
        goldPriceTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshGoldPrice()
                try? await Task.sleep(for: self?.goldPriceRefreshInterval ?? .seconds(24 * 60 * 60))
            }
        }
    }

    private func refreshGoldPrice() async {
        do {
            let quote = try await goldPriceService.fetchCNYPerGram()
            goldPriceText = quote.cnyPerGram.goldPriceText
        } catch {
            if goldPriceText == "金价 --" {
                goldPriceText = goldPriceFallbackText(for: error)
            }
        }
        refreshIcon()
    }

    private func goldPriceFallbackText(for error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("frequency") || message.contains("rate") || message.contains("call") {
            return "金价限频"
        }
        if message.contains("internet") || message.contains("network") || message.contains("offline") {
            return "金价网络失败"
        }
        return "金价解析失败"
    }
}

private enum CoinIconRenderer {
    static func image(phase: Double) -> NSImage {
        let size = NSSize(width: 24, height: 18)
        let image = NSImage(size: size)

        image.lockFocus()
        defer { image.unlockFocus() }

        let rotation = CGFloat(phase)
        let faceAmount = abs(cos(rotation))
        let width = 2.8 + 14.2 * faceAmount
        let height = 13.2
        let coinRect = NSRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )

        let coin = NSBezierPath(ovalIn: coinRect)
        NSColor(calibratedRed: 1.0, green: 0.76, blue: 0.18, alpha: 1).setFill()
        coin.fill()

        NSColor(calibratedRed: 0.86, green: 0.48, blue: 0.05, alpha: 1).setStroke()
        coin.lineWidth = 1.4
        coin.stroke()

        if width > 6.6 {
            let inner = NSBezierPath(ovalIn: coinRect.insetBy(dx: 2.1, dy: 2.1))
            NSColor(calibratedRed: 0.96, green: 0.62, blue: 0.08, alpha: 0.55).setStroke()
            inner.lineWidth = 0.9
            inner.stroke()

            let shine = NSBezierPath()
            shine.lineWidth = 1.0
            shine.lineCapStyle = .round
            NSColor.white.withAlphaComponent(0.75).setStroke()
            let shineOffset = sin(rotation) * width * 0.14
            shine.move(to: NSPoint(x: coinRect.midX - width * 0.20 + shineOffset, y: coinRect.midY + 3.1))
            shine.line(to: NSPoint(x: coinRect.midX + width * 0.10 + shineOffset, y: coinRect.midY + 3.8))
            shine.stroke()

            let symbol = "¥" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 8.5, weight: .bold),
                .foregroundColor: NSColor(calibratedRed: 0.82, green: 0.42, blue: 0.02, alpha: 1)
            ]
            let symbolSize = symbol.size(withAttributes: attributes)
            symbol.draw(
                at: NSPoint(x: coinRect.midX - symbolSize.width / 2, y: coinRect.midY - symbolSize.height / 2),
                withAttributes: attributes
            )
        } else {
            let edge = NSBezierPath()
            edge.lineWidth = 1.8
            edge.lineCapStyle = .round
            NSColor(calibratedRed: 0.82, green: 0.42, blue: 0.02, alpha: 1).setStroke()
            edge.move(to: NSPoint(x: coinRect.midX, y: coinRect.minY + 1.4))
            edge.line(to: NSPoint(x: coinRect.midX, y: coinRect.maxY - 1.4))
            edge.stroke()
        }

        image.isTemplate = false
        return image
    }
}

private extension Double {
    var goldPriceText: String {
        "¥" + formatted(.number.precision(.fractionLength(2))) + "/g"
    }
}
#endif
