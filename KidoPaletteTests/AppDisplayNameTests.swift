//
//  AppDisplayNameTests.swift
//  KidoPaletteTests
//

import Foundation
import Testing
@testable import KidoPalette

struct AppDisplayNameTests {

    @Test func resolveReturnsFinderLocalizedDisplayNameForExistingApp() throws {
        let path = try #require(Self.existingAppPath())
        let url = URL(fileURLWithPath: path)
        let metadataName = try #require(
            NSMetadataItem(url: url)?.value(forAttribute: kMDItemDisplayName as String) as? String
        )
        let expected = metadataName.lowercased().hasSuffix(".app")
            ? String(metadataName.dropLast(4))
            : metadataName

        let resolved = AppDisplayName.resolve(bundlePath: path)

        #expect(!resolved.isEmpty)
        #expect(resolved == expected)
    }

    @Test func resolveFallsBackToPathNameWhenAppIsMissing() {
        let path = "/Applications/KidoPaletteMissingApp12345.app"
        let resolved = AppDisplayName.resolve(bundlePath: path)
        #expect(resolved == "KidoPaletteMissingApp12345")
    }

    private static func existingAppPath() -> String? {
        let candidates = [
            "/System/Applications/Mail.app",
            "/System/Applications/System Settings.app",
            "/Applications/Safari.app",
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0) }
    }
}
