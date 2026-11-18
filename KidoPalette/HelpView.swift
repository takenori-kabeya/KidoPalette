//
//  HelpView.swift
//  KidoPalette
//

import AppKit
import SwiftUI

enum HelpWindowMetrics {
    static let defaultWidth: CGFloat = 720
    static let defaultHeight: CGFloat = 780
    static let minimumWidth: CGFloat = 560
    static let minimumHeight: CGFloat = 520
}

struct HelpView: View {
    private let help: Result<NSAttributedString, Error> = Result {
        try HelpDocument.bundledHelpAttributedString()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch help {
            case .success(let attributed):
                AttributedTextScrollView(attributedString: attributed)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failure:
                Text("Could not load the Help document.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding(20)
        .frame(
            minWidth: HelpWindowMetrics.minimumWidth,
            idealWidth: HelpWindowMetrics.defaultWidth,
            minHeight: HelpWindowMetrics.minimumHeight,
            idealHeight: HelpWindowMetrics.defaultHeight
        )
    }
}

struct HelpCommandButton: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("KidoPalette Help") {
            openWindow(id: "help")
        }
        .keyboardShortcut("?", modifiers: .command)
    }
}
