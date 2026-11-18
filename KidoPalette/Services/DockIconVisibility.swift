//
//  DockIconVisibility.swift
//  KidoPalette
//

import AppKit

enum DockIconVisibility {
    @MainActor
    static func apply(showsDockIcon: Bool) {
        _ = NSApp.setActivationPolicy(showsDockIcon ? .regular : .accessory)
    }
}
