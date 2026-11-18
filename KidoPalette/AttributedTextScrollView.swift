//
//  AttributedTextScrollView.swift
//  KidoPalette
//

import AppKit
import SwiftUI

struct AttributedTextScrollView: NSViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    let attributedString: NSAttributedString

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 8, height: 10)
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 5
        textView.textStorage?.setAttributedString(attributedString)
        LicenseDocument.applyAdaptiveColors(to: textView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        _ = colorScheme
        if textView.attributedString().isEqual(attributedString) == false {
            textView.textStorage?.setAttributedString(attributedString)
        }
        LicenseDocument.applyAdaptiveColors(to: textView)
    }
}
