//
//  AppDelegate.swift
//  KidoPalette
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var launcherController: LauncherController?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        Task { @MainActor in
            launcherController?.show()
        }
        return true
    }
}
