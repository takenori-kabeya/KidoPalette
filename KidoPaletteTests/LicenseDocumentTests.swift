//
//  LicenseDocumentTests.swift
//  KidoPaletteTests
//

import AppKit
import Foundation
import Testing
@testable import KidoPalette

struct LicenseDocumentTests {

    @Test func attributedStringLoadsRTFContent() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KidoPaletteEULA-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rtfURL = directory.appendingPathComponent("sample.rtf")
        let rtf = """
        {\\rtf1\\ansi\\deff0
        {\\fonttbl{\\f0 Helvetica;}}
        \\f0\\fs24 KidoPalette EULA sample paragraph.\\par
        }
        """
        try Data(rtf.utf8).write(to: rtfURL)

        let attributed = try LicenseDocument.attributedString(contentsOfRTF: rtfURL)
        #expect(attributed.string.contains("KidoPalette EULA sample paragraph."))
    }

    @Test func bundledCreditsRTFIsPresentAndReadable() throws {
        let url = try #require(LicenseDocument.bundledCreditsURL())
        let attributed = try LicenseDocument.attributedString(contentsOfRTF: url)
        #expect(attributed.string.contains("KidoPalette"))
        #expect(attributed.string.contains("EULA"))
    }

    @Test func applyingAdaptiveForegroundColorsUsesLabelColor() {
        let source = NSAttributedString(
            string: "EULA body",
            attributes: [.foregroundColor: NSColor.black]
        )
        let adapted = LicenseDocument.applyingAdaptiveForegroundColors(to: source)
        var effectiveRange = NSRange(location: 0, length: 0)
        let color = adapted.attribute(
            .foregroundColor,
            at: 0,
            effectiveRange: &effectiveRange
        ) as? NSColor

        #expect(color == NSColor.labelColor)
        #expect(effectiveRange.length == adapted.length)
    }
}
