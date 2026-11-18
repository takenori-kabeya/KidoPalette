//
//  AboutWindowTests.swift
//  KidoPaletteTests
//

import Foundation
import Testing
@testable import KidoPalette

struct AboutWindowTests {

    @Test func defaultSizeIsLargeEnoughToReadEULA() {
        #expect(AboutWindowMetrics.defaultWidth >= 640)
        #expect(AboutWindowMetrics.defaultHeight >= 720)
        #expect(AboutWindowMetrics.minimumWidth >= 520)
        #expect(AboutWindowMetrics.minimumHeight >= 480)
    }

    @Test func bundledCreditsLoadForAboutDisplay() throws {
        let attributed = try LicenseDocument.bundledCreditsAttributedString()
        #expect(!attributed.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        #expect(attributed.string.contains("EULA"))
    }
}
