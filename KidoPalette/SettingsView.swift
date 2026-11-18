//
//  SettingsView.swift
//  KidoPalette
//

import SwiftUI

struct SettingsView: View {
    @Bindable var store: LauncherStore

    var body: some View {
        Form {
            Section("Hot Corners") {
                Toggle("Enable Hot Corner", isOn: hotCornerEnabledBinding)

                Picker("Trigger corner", selection: hotCornerBinding) {
                    Text("Bottom Left").tag(HotCorner.bottomLeft)
                    Text("Bottom Right").tag(HotCorner.bottomRight)
                    Text("Top Left").tag(HotCorner.topLeft)
                    Text("Top Right").tag(HotCorner.topRight)
                }
                .pickerStyle(.radioGroup)
                .disabled(!store.state.hotCornerEnabled)

                Toggle("Show Full Screen", isOn: hotCornerShowsFullscreenBinding)
            }

            Section("Dock") {
                Toggle("Show in Dock", isOn: showsDockIconBinding)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 360)
        .padding()
    }

    private var hotCornerEnabledBinding: Binding<Bool> {
        Binding(
            get: { store.state.hotCornerEnabled },
            set: { store.setHotCornerEnabled($0) }
        )
    }

    private var hotCornerBinding: Binding<HotCorner> {
        Binding(
            get: { store.state.hotCorner },
            set: { store.setHotCorner($0) }
        )
    }

    private var hotCornerShowsFullscreenBinding: Binding<Bool> {
        Binding(
            get: { store.state.hotCornerShowsFullscreen },
            set: { store.setHotCornerShowsFullscreen($0) }
        )
    }

    private var showsDockIconBinding: Binding<Bool> {
        Binding(
            get: { store.state.showsDockIcon },
            set: { store.setShowsDockIcon($0) }
        )
    }
}
