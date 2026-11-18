//
//  LicenseDocument.swift
//  KidoPalette
//

import AppKit
import Foundation

enum LicenseDocument {
    static func bundledCreditsURL() -> URL? {
        Bundle.main.url(forResource: "Credits", withExtension: "rtf")
    }

    static func bundledCreditsAttributedString() throws -> NSAttributedString {
        guard let url = bundledCreditsURL() else {
            throw LicenseDocumentError.creditsMissing
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

    /// pandoc 生成 RTF の固定前景色を、ライト／ダーク両対応の labelColor に置き換える。
    static func applyingAdaptiveForegroundColors(to attributed: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributed)
        guard mutable.length > 0 else { return mutable }
        mutable.addAttribute(
            .foregroundColor,
            value: NSColor.labelColor,
            range: NSRange(location: 0, length: mutable.length)
        )
        return mutable
    }

    static func applyAdaptiveColors(to textView: NSTextView) {
        textView.textColor = .labelColor
        guard let storage = textView.textStorage, storage.length > 0 else { return }
        storage.addAttribute(
            .foregroundColor,
            value: NSColor.labelColor,
            range: NSRange(location: 0, length: storage.length)
        )
    }
}

enum LicenseDocumentError: Error {
    case creditsMissing
}
