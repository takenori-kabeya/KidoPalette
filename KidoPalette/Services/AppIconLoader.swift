//
//  AppIconLoader.swift
//  KidoPalette
//

import AppKit
import Foundation

enum AppIconLoader {
    static func icon(for app: RegisteredApp, size: CGFloat = 64) -> NSImage {
        if let bookmarkData = app.bookmarkData {
            if let icon = try? SecurityScopedBookmark.access(bookmarkData, { url in
                makeIcon(forPath: url.path, size: size)
            }) {
                return icon
            }
        }
        return makeIcon(forPath: app.bundlePath, size: size)
    }

    private static func makeIcon(forPath path: String, size: CGFloat) -> NSImage {
        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: size, height: size)
        return icon
    }
}
