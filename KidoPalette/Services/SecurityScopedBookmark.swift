//
//  SecurityScopedBookmark.swift
//  KidoPalette
//

import Foundation

enum SecurityScopedBookmark {
    static func make(from url: URL) throws -> Data {
        try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    static func resolve(_ data: Data) throws -> URL {
        var isStale = false
        return try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
    }

    static func access<T>(_ data: Data, _ body: (URL) throws -> T) throws -> T {
        let url = try resolve(data)
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try body(url)
    }
}
