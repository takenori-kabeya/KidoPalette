//
//  AppLauncher.swift
//  KidoPalette
//

import AppKit
import Foundation

enum AppLauncher {
    @discardableResult
    static func launch(_ app: RegisteredApp) -> Bool {
        if let bookmarkData = app.bookmarkData {
            return (try? SecurityScopedBookmark.access(bookmarkData) { url in
                NSWorkspace.shared.open(url)
            }) ?? false
        }
        return NSWorkspace.shared.open(URL(fileURLWithPath: app.bundlePath))
    }
}
