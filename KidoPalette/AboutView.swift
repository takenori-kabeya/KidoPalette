//
//  AboutView.swift
//  KidoPalette
//

import AppKit
import SwiftUI

enum AboutWindowMetrics {
    static let defaultWidth: CGFloat = 720
    static let defaultHeight: CGFloat = 780
    static let minimumWidth: CGFloat = 560
    static let minimumHeight: CGFloat = 520
}

struct AboutView: View {
    private let credits: Result<NSAttributedString, Error> = Result {
        try LicenseDocument.bundledCreditsAttributedString()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()
            eulaSection
        }
        .padding(20)
        .frame(
            minWidth: AboutWindowMetrics.minimumWidth,
            idealWidth: AboutWindowMetrics.defaultWidth,
            minHeight: AboutWindowMetrics.minimumHeight,
            idealHeight: AboutWindowMetrics.defaultHeight
        )
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(appName)
                    .font(.title2.weight(.semibold))
                Text(versionLine)
                    .foregroundStyle(.secondary)
                if let copyright {
                    Text(copyright)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var eulaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("End User License Agreement")
                .font(.headline)

            switch credits {
            case .success(let attributed):
                AttributedTextScrollView(attributedString: attributed)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failure:
                Text("Could not load the EULA document.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "KidoPalette"
    }

    private var versionLine: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "Version \(version) (\(build))"
    }

    private var copyright: String? {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
    }
}

struct AboutCommandButton: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("About KidoPalette") {
            openWindow(id: "about")
        }
    }
}
