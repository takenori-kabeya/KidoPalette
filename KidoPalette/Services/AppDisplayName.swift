//
//  AppDisplayName.swift
//  KidoPalette
//

import Foundation

enum AppDisplayName {
    static func resolve(bundlePath: String) -> String {
        resolve(bundleURL: URL(fileURLWithPath: bundlePath))
    }

    static func resolve(_ app: RegisteredApp) -> String {
        if let bookmarkData = app.bookmarkData {
            if let name = try? SecurityScopedBookmark.access(bookmarkData, { url in
                resolve(bundleURL: url)
            }) {
                return name
            }
        }
        return resolve(bundleURL: URL(fileURLWithPath: app.bundlePath))
    }

    static func resolve(bundleURL: URL) -> String {
        if let metadataName = NSMetadataItem(url: bundleURL)?
            .value(forAttribute: kMDItemDisplayName as String) as? String {
            let trimmed = stripAppExtension(metadataName)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        if let bundle = Bundle(url: bundleURL) {
            if let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
               !displayName.isEmpty {
                return displayName
            }
            if let bundleName = bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String,
               !bundleName.isEmpty {
                return bundleName
            }
        }

        let fileManagerName = stripAppExtension(FileManager.default.displayName(atPath: bundleURL.path))
        if !fileManagerName.isEmpty {
            return fileManagerName
        }

        return bundleURL.deletingPathExtension().lastPathComponent
    }

    private static func stripAppExtension(_ name: String) -> String {
        if name.lowercased().hasSuffix(".app") {
            return String(name.dropLast(4))
        }
        return name
    }
}
