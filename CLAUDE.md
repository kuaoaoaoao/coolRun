# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

coolRun is a macOS menu bar utility that displays system monitoring metrics (CPU, memory, storage, battery, network) and real-time gold prices from 浙商银行积存金 API. It runs as a menu bar-only app (no Dock icon by default).

## Build & Run

Open `coolRun.xcodeproj` in Xcode, select the `coolRun` scheme with target `My Mac`, and click Run. There are no tests, no linter configuration, and no CLI build commands — all building is done through Xcode.

To build from command line (if needed):
```bash
xcodebuild -project coolRun.xcodeproj -scheme coolRun -configuration Debug build
```

To create a DMG for distribution:
```bash
./scripts/create-dmg.sh /path/to/coolRun.app
```

## Architecture

The app uses SwiftUI with an `NSApplicationDelegateAdaptor` pattern to bridge AppKit's `NSStatusItem` menu bar integration with SwiftUI views.

**Data flow:**
- `SystemSampler` (low-level Darwin/IOKit calls) → `SystemMonitorViewModel` (1-second refresh timer, `@Observable`) → SwiftUI views
- `GoldPriceService` (async HTTP) → `MacAppDelegate` → menu bar title

**Key components:**

- `coolRunApp.swift` — Entry point. Registers `MacAppDelegate` on macOS; provides `Settings` scene (not a window group).
- `MacAppDelegate.swift` — Core orchestrator. Manages `NSStatusItem`, popover panels, coin icon animation (CPU-driven rotation speed), gold price polling (default 1s interval via `goldPriceRefreshInterval`), and Dock icon visibility toggling. Contains `CoinIconRenderer` (programmatic NSImage drawing) and `StatusContextMenuView`.
- `SystemSampler.swift` — Raw system data collection using Mach kernel APIs (`host_statistics`, `host_statistics64`), IOKit (`IOPSCopyPowerSourcesInfo`), and POSIX (`getifaddrs`). Tracks CPU tick deltas across calls.
- `SystemMonitorViewModel.swift` — `@Observable` + `@MainActor` wrapper. Holds a `SystemSnapshot` and drives a 1-second refresh loop via `Task.sleep`.
- `SystemMetrics.swift` — Pure value types: `SystemSnapshot`, `CPUMetrics`, `MemoryMetrics`, `StorageMetrics`, `BatteryMetrics`, `NetworkMetrics`.
- `ContentView.swift` — Full monitoring panel UI (`MonitorPanel` and section views). Also defines `AppTheme` colors and byte-count formatting extensions.
- `MenuBarMonitorView.swift` — Thin wrapper around `MonitorPanel` for the popover context.
- `GoldPriceService.swift` — Fetches gold price from `api.jdjygold.com`, decodes nested JSON (`ZSBankGoldPriceResponse`). Returns `GoldPriceQuote`.
- `SettingsView.swift` — Tab-based settings (About + Update). Contains `AppLinks` enum with GitHub URLs.
- `AppVersion.swift` — Reads `CFBundleShortVersionString` / `CFBundleVersion` from the bundle.

## Key Technical Details

- The app uses `NSApp.setActivationPolicy(.accessory)` to hide the Dock icon, toggling to `.regular` only when the Settings window is open.
- The gold coin icon in the menu bar is rendered programmatically via `CoinIconRenderer` (no image assets) — rotation phase is driven by CPU usage.
- System sampling uses low-level C APIs (Darwin, IOKit, not SystemConfiguration) — `SystemSampler` is the only file that touches these.
- Battery state has cross-platform support (`#if os(macOS)` / `#elseif canImport(UIKit)`) though the app is currently macOS-only.
- App Sandbox is enabled with `com.apple.security.network.client` entitlement for the gold price API call.
- Deployment target is macOS 26.4. Swift 5.0 (uses Swift 5.9+ `@Observable` macro).
- Sparkle auto-update was removed; updates are manual via GitHub Releases. See `SPARKLE_SETUP.md` if re-enabling.

## Conventions

- UI strings are in Chinese (Simplified).
- All source files are in the flat `coolRun/` directory — no subdirectories or module separation.
- No external package dependencies (Sparkle was removed).
- The gold price refresh interval is configurable in `MacAppDelegate.swift` (`goldPriceRefreshInterval`).
