//
//  SecurityScopedBookmarkTests.swift
//  KidoPaletteTests
//

import Foundation
import Testing
@testable import KidoPalette

struct SecurityScopedBookmarkTests {

    @Test func makeAndResolveRoundTripsTemporaryAppBundle() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KidoPaletteBookmark-\(UUID().uuidString)", isDirectory: true)
        let appURL = directory.appendingPathComponent("Sample.app", isDirectory: true)
        try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let bookmark = try SecurityScopedBookmark.make(from: appURL)
        let resolved = try SecurityScopedBookmark.resolve(bookmark)

        #expect(resolved.standardizedFileURL.path == appURL.standardizedFileURL.path)
    }

    @Test func accessProvidesResolvedURL() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KidoPaletteBookmark-\(UUID().uuidString)", isDirectory: true)
        let appURL = directory.appendingPathComponent("Access.app", isDirectory: true)
        try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let bookmark = try SecurityScopedBookmark.make(from: appURL)
        let path = try SecurityScopedBookmark.access(bookmark) { url in
            url.standardizedFileURL.path
        }

        #expect(path == appURL.standardizedFileURL.path)
    }

    @Test func registeredAppCodablePreservesBookmarkData() throws {
        let bookmark = Data([0x01, 0x02, 0x03, 0x04])
        let app = RegisteredApp(
            id: UUID(),
            bundlePath: "/Applications/Safari.app",
            displayName: "Safari",
            bookmarkData: bookmark
        )

        let encoded = try JSONEncoder().encode(app)
        let decoded = try JSONDecoder().decode(RegisteredApp.self, from: encoded)

        #expect(decoded.id == app.id)
        #expect(decoded.bundlePath == app.bundlePath)
        #expect(decoded.displayName == app.displayName)
        #expect(decoded.bookmarkData == bookmark)
    }

    @Test func registeredAppCodableAllowsMissingBookmarkData() throws {
        let json = """
        {"id":"00000000-0000-0000-0000-000000000001","bundlePath":"/Applications/Mail.app","displayName":"Mail"}
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(RegisteredApp.self, from: json)

        #expect(decoded.bundlePath == "/Applications/Mail.app")
        #expect(decoded.displayName == "Mail")
        #expect(decoded.bookmarkData == nil)
    }
}
