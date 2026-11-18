//
//  HelpDocumentTests.swift
//  KidoPaletteTests
//

import AppKit
import Foundation
import Testing
@testable import KidoPalette

struct HelpDocumentTests {

    @Test func japanesePreferredLanguageSelectsJapaneseHelpResource() {
        #expect(HelpDocument.helpResourceName(preferredLanguages: ["ja-JP"]) == "Help.ja")
        #expect(HelpDocument.helpResourceName(preferredLanguages: ["ja"]) == "Help.ja")
    }

    @Test func englishPreferredLanguageSelectsEnglishHelpResource() {
        #expect(HelpDocument.helpResourceName(preferredLanguages: ["en"]) == "Help")
        #expect(HelpDocument.helpResourceName(preferredLanguages: ["en-US", "ja"]) == "Help")
    }

    @Test func bundledEnglishAndJapaneseHelpRTFArePresentAndReadable() throws {
        let englishURL = try #require(Bundle.main.url(forResource: "Help", withExtension: "rtf"))
        let japaneseURL = try #require(Bundle.main.url(forResource: "Help.ja", withExtension: "rtf"))

        let english = try HelpDocument.attributedString(contentsOfRTF: englishURL)
        let japanese = try HelpDocument.attributedString(contentsOfRTF: japaneseURL)

        #expect(english.string.contains("KidoPalette"))
        #expect(english.string.contains("Hot corner") || english.string.contains("Getting started"))
        #expect(japanese.string.contains("KidoPalette"))
        #expect(japanese.string.contains("ホットコーナー") || japanese.string.contains("ヘルプ"))
    }

    @Test func preferredHelpLoadsForCurrentLocale() throws {
        let attributed = try HelpDocument.bundledHelpAttributedString()
        #expect(!attributed.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        #expect(attributed.string.contains("KidoPalette"))
    }

    @Test func helpWindowDefaultSizeIsLargeEnoughToRead() {
        #expect(HelpWindowMetrics.defaultWidth >= 640)
        #expect(HelpWindowMetrics.defaultHeight >= 720)
        #expect(HelpWindowMetrics.minimumWidth >= 520)
        #expect(HelpWindowMetrics.minimumHeight >= 480)
    }
}
