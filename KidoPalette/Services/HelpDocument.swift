//
//  HelpDocument.swift
//  KidoPalette
//

import AppKit
import Foundation

enum HelpDocument {
    static func helpResourceName(preferredLanguages: [String] = Locale.preferredLanguages) -> String {
        if preferredLanguages.first?.hasPrefix("ja") == true {
            return "Help.ja"
        }
        return "Help"
    }

    static func bundledHelpURL(
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> URL? {
        let preferredName = helpResourceName(preferredLanguages: preferredLanguages)
        if let url = Bundle.main.url(forResource: preferredName, withExtension: "rtf") {
            return url
        }
        return Bundle.main.url(forResource: "Help", withExtension: "rtf")
    }

    static func bundledHelpAttributedString(
        preferredLanguages: [String] = Locale.preferredLanguages
    ) throws -> NSAttributedString {
        guard let url = bundledHelpURL(preferredLanguages: preferredLanguages) else {
            throw HelpDocumentError.helpMissing
        }
        return try attributedString(contentsOfRTF: url)
    }

    static func attributedString(contentsOfRTF url: URL) throws -> NSAttributedString {
        try NSAttributedString(
            url: url,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
    }
}

enum HelpDocumentError: Error {
    case helpMissing
}
