//
//  coolRunApp.swift
//  coolRun
//
//  Created by kuao on 2026/5/21.
//

import SwiftUI

@main
struct coolRunApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        #if os(macOS)
        Settings {
            EmptyView()
        }
        #else
        WindowGroup {
            ContentView()
        }
        #endif
    }
}
