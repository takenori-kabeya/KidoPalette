//
//  LauncherStore.swift
//  KidoPalette
//

import Foundation
import Observation

@Observable
final class LauncherStore {
    private(set) var state: LauncherState
    private let persistence: any LauncherPersisting

    var selectedTab: AppTab? {
        guard let selectedTabID = state.selectedTabID else { return nil }
        return state.tabs.first { $0.id == selectedTabID }
    }

    init(persistence: any LauncherPersisting = FileLauncherPersistence()) {
        self.persistence = persistence
        if let loaded = try? persistence.load() {
            self.state = loaded
        } else {
            self.state = .makeDefault()
            persist()
        }
    }

    @discardableResult
    func addTab(name: String) -> AppTab {
        let tab = AppTab(id: UUID(), name: name, apps: [])
        state.tabs.append(tab)
        state.selectedTabID = tab.id
        persist()
        return tab
    }

    func renameTab(id: UUID, name: String) {
        guard let index = state.tabs.firstIndex(where: { $0.id == id }) else { return }
        state.tabs[index].name = name
        persist()
    }

    func deleteTab(id: UUID) {
        guard state.tabs.count > 1 else { return }
        guard let index = state.tabs.firstIndex(where: { $0.id == id }) else { return }
        state.tabs.remove(at: index)
        if state.selectedTabID == id {
            state.selectedTabID = state.tabs[min(index, state.tabs.count - 1)].id
        }
        persist()
    }

    func selectTab(id: UUID) {
        guard state.tabs.contains(where: { $0.id == id }) else { return }
        state.selectedTabID = id
        persist()
    }

    @discardableResult
    func registerApp(bundleURL: URL, displayName: String, at insertionIndex: Int? = nil) -> RegisteredApp {
        let bookmarkData = try? SecurityScopedBookmark.make(from: bundleURL)
        let app = RegisteredApp(
            id: UUID(),
            bundlePath: bundleURL.path,
            displayName: displayName,
            bookmarkData: bookmarkData
        )
        guard let selectedTabID = state.selectedTabID,
              let index = state.tabs.firstIndex(where: { $0.id == selectedTabID }) else {
            return app
        }
        if let insertionIndex {
            let clamped = min(max(insertionIndex, 0), state.tabs[index].apps.count)
            state.tabs[index].apps.insert(app, at: clamped)
        } else {
            state.tabs[index].apps.append(app)
        }
        persist()
        return app
    }

    func removeApp(id: UUID) {
        for tabIndex in state.tabs.indices {
            if let appIndex = state.tabs[tabIndex].apps.firstIndex(where: { $0.id == id }) {
                state.tabs[tabIndex].apps.remove(at: appIndex)
                persist()
                return
            }
        }
    }

    func moveApp(id: UUID, toTabID: UUID) {
        guard let destinationIndex = state.tabs.firstIndex(where: { $0.id == toTabID }) else { return }

        var moved: RegisteredApp?
        for tabIndex in state.tabs.indices {
            if let appIndex = state.tabs[tabIndex].apps.firstIndex(where: { $0.id == id }) {
                moved = state.tabs[tabIndex].apps.remove(at: appIndex)
                break
            }
        }

        guard let app = moved else { return }
        state.tabs[destinationIndex].apps.append(app)
        persist()
    }

    func reorderApp(id: UUID, toIndex: Int) {
        guard let tabIndex = state.tabs.firstIndex(where: { tab in
            tab.apps.contains(where: { $0.id == id })
        }) else {
            return
        }

        var apps = state.tabs[tabIndex].apps
        guard let fromIndex = apps.firstIndex(where: { $0.id == id }) else { return }
        guard apps.indices.contains(toIndex) else { return }
        guard fromIndex != toIndex else { return }

        let app = apps.remove(at: fromIndex)
        let insertIndex = min(toIndex, apps.count)
        apps.insert(app, at: insertIndex)
        state.tabs[tabIndex].apps = apps
        persist()
    }

    func reorderTab(id: UUID, toIndex: Int) {
        guard let fromIndex = state.tabs.firstIndex(where: { $0.id == id }) else { return }
        guard state.tabs.indices.contains(toIndex) else { return }
        guard fromIndex != toIndex else { return }

        var tabs = state.tabs
        let tab = tabs.remove(at: fromIndex)
        let insertIndex = min(toIndex, tabs.count)
        tabs.insert(tab, at: insertIndex)
        state.tabs = tabs
        persist()
    }

    func destinationTabs(forAppID appID: UUID) -> [AppTab] {
        guard let sourceTab = state.tabs.first(where: { tab in
            tab.apps.contains(where: { $0.id == appID })
        }) else {
            return []
        }
        return state.tabs.filter { $0.id != sourceTab.id }
    }

    func setHotCorner(_ corner: HotCorner) {
        state.hotCorner = corner
        persist()
    }

    func setHotCornerEnabled(_ enabled: Bool) {
        state.hotCornerEnabled = enabled
        persist()
    }

    func setHotCornerShowsFullscreen(_ showsFullscreen: Bool) {
        state.hotCornerShowsFullscreen = showsFullscreen
        persist()
    }

    func setShowsDockIcon(_ showsDockIcon: Bool) {
        state.showsDockIcon = showsDockIcon
        persist()
        Task { @MainActor in
            DockIconVisibility.apply(showsDockIcon: showsDockIcon)
        }
    }

    private func persist() {
        try? persistence.save(state)
    }
}
