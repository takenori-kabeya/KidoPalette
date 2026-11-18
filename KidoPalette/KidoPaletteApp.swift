//
//  KidoPaletteApp.swift
//  KidoPalette
//

import AppKit
import SwiftUI

@main
struct KidoPaletteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = LauncherStore()
    @State private var controller: LauncherController?

    var body: some Scene {
        Window("KidoPalette", id: "launcher") {
            Group {
                if let controller {
                    LauncherView(
                        store: store,
                        onDismiss: { controller.hide() },
                        onLaunchApp: { app in controller.launchAndHide(app) }
                    )
                } else {
                    ProgressView()
                        .frame(minWidth: 640, minHeight: 420)
                }
            }
            .background(WindowAccessor { window in
                window.identifier = NSUserInterfaceItemIdentifier("launcher")
                window.title = "KidoPalette"
            })
            .onAppear {
                bootstrapIfNeeded()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 800, height: 560)
        .commands {
            CommandGroup(replacing: .appInfo) {
                AboutCommandButton()
            }
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .help) {
                HelpCommandButton()
            }
            CommandGroup(after: .windowList) {
                Button("Toggle Visibility") {
                    controller?.toggleVisibility()
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            }
        }

        Window("About KidoPalette", id: "about") {
            AboutView()
        }
        .windowResizability(.contentMinSize)
        .defaultSize(
            width: AboutWindowMetrics.defaultWidth,
            height: AboutWindowMetrics.defaultHeight
        )

        Window("KidoPalette Help", id: "help") {
            HelpView()
        }
        .windowResizability(.contentMinSize)
        .defaultSize(
            width: HelpWindowMetrics.defaultWidth,
            height: HelpWindowMetrics.defaultHeight
        )

        Settings {
            SettingsView(store: store)
        }
    }

    private func bootstrapIfNeeded() {
        guard controller == nil else { return }
        let launcher = LauncherController(store: store)
        controller = launcher
        appDelegate.launcherController = launcher
        DockIconVisibility.apply(showsDockIcon: store.state.showsDockIcon)
        DispatchQueue.main.async {
            launcher.start()
        }
    }
}

private struct WindowAccessor: NSViewRepresentable {
    var onResolve: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onResolve(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                onResolve(window)
            }
        }
    }
}
