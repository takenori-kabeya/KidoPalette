//
//  LauncherStoreTests.swift
//  KidoPaletteTests
//

import Foundation
import Testing
@testable import KidoPalette

struct LauncherStoreTests {

    @Test func initialStateHasOneDefaultTabAndBottomLeftHotCorner() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())

        #expect(store.state.tabs.count == 1)
        #expect(store.state.tabs[0].name == String(localized: "Apps"))
        #expect(store.state.tabs[0].apps.isEmpty)
        #expect(store.state.selectedTabID == store.state.tabs[0].id)
        #expect(store.state.hotCorner == .bottomLeft)
        #expect(store.state.hotCornerEnabled == true)
        #expect(store.state.showsDockIcon == true)
        #expect(store.state.hotCornerShowsFullscreen == false)
    }

    @Test func addTabAppendsAndSelectsNewTab() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let firstTabID = store.state.tabs[0].id

        let newTab = store.addTab(name: "Work")

        #expect(store.state.tabs.count == 2)
        #expect(store.state.tabs[1].id == newTab.id)
        #expect(store.state.tabs[1].name == "Work")
        #expect(store.state.selectedTabID == newTab.id)
        #expect(store.state.tabs[0].id == firstTabID)
    }

    @Test func renameTabUpdatesName() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let tabID = store.state.tabs[0].id

        store.renameTab(id: tabID, name: "Favorites")

        #expect(store.state.tabs[0].name == "Favorites")
    }

    @Test func deleteTabRemovesTabAndSelectsAnother() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let firstID = store.state.tabs[0].id
        let second = store.addTab(name: "Work")

        store.deleteTab(id: firstID)

        #expect(store.state.tabs.count == 1)
        #expect(store.state.tabs[0].id == second.id)
        #expect(store.state.selectedTabID == second.id)
    }

    @Test func deleteLastTabIsNotAllowed() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let onlyID = store.state.tabs[0].id

        store.deleteTab(id: onlyID)

        #expect(store.state.tabs.count == 1)
        #expect(store.state.tabs[0].id == onlyID)
        #expect(store.state.selectedTabID == onlyID)
    }

    @Test func selectTabChangesSelectedTabID() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let second = store.addTab(name: "Work")
        let firstID = store.state.tabs[0].id

        store.selectTab(id: firstID)

        #expect(store.state.selectedTabID == firstID)
        #expect(second.id != firstID)
    }

    @Test func registerAppAddsToSelectedTab() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())

        let app = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/Safari.app"), displayName: "Safari")

        #expect(store.state.tabs[0].apps.count == 1)
        #expect(store.state.tabs[0].apps[0].id == app.id)
        #expect(store.state.tabs[0].apps[0].bundlePath == "/Applications/Safari.app")
        #expect(store.state.tabs[0].apps[0].displayName == "Safari")
    }

    @Test func registerAppInsertsAtIndexInSelectedTab() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        _ = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/A.app"), displayName: "A")
        _ = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/B.app"), displayName: "B")
        _ = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/C.app"), displayName: "C")

        _ = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/D.app"), displayName: "D", at: 1)
        #expect(store.state.tabs[0].apps.map(\.displayName) == ["A", "D", "B", "C"])

        _ = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/E.app"), displayName: "E", at: 0)
        #expect(store.state.tabs[0].apps.map(\.displayName) == ["E", "A", "D", "B", "C"])

        let endIndex = store.state.tabs[0].apps.count
        _ = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/F.app"), displayName: "F", at: endIndex)
        #expect(store.state.tabs[0].apps.map(\.displayName) == ["E", "A", "D", "B", "C", "F"])
    }

    @Test func sameAppCanBeRegisteredInMultipleTabsWithDistinctIDs() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let first = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/Safari.app"), displayName: "Safari")
        let work = store.addTab(name: "Work")
        let second = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/Safari.app"), displayName: "Safari")

        #expect(first.id != second.id)
        #expect(store.state.tabs[0].apps.count == 1)
        #expect(work.apps.count == 0)
        #expect(store.state.tabs.first { $0.id == work.id }?.apps.count == 1)
        #expect(store.state.tabs[0].apps[0].bundlePath == store.state.tabs[1].apps[0].bundlePath)
    }

    @Test func removeAppRemovesOnlyThatRegistration() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let first = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/Safari.app"), displayName: "Safari")
        _ = store.addTab(name: "Work")
        let second = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/Safari.app"), displayName: "Safari")

        store.removeApp(id: first.id)

        #expect(store.state.tabs[0].apps.isEmpty)
        #expect(store.state.tabs[1].apps.count == 1)
        #expect(store.state.tabs[1].apps[0].id == second.id)
    }

    @Test func moveAppMovesRegistrationBetweenTabs() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let app = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/Mail.app"), displayName: "Mail")
        let work = store.addTab(name: "Work")
        let sourceID = store.state.tabs[0].id

        store.moveApp(id: app.id, toTabID: work.id)

        #expect(store.state.tabs.first { $0.id == sourceID }?.apps.isEmpty == true)
        #expect(store.state.tabs.first { $0.id == work.id }?.apps.count == 1)
        #expect(store.state.tabs.first { $0.id == work.id }?.apps[0].id == app.id)
        #expect(store.state.tabs.first { $0.id == work.id }?.apps[0].bundlePath == "/Applications/Mail.app")
    }

    @Test func setHotCornerUpdatesState() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())

        store.setHotCorner(.topRight)

        #expect(store.state.hotCorner == .topRight)
    }

    @Test func setHotCornerEnabledUpdatesState() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())

        store.setHotCornerEnabled(false)

        #expect(store.state.hotCornerEnabled == false)
        #expect(store.state.hotCorner == .bottomLeft)
    }

    @Test func launcherStateDecodesMissingHotCornerEnabledAsTrue() throws {
        let json = """
        {
          "tabs": [{"id":"00000000-0000-0000-0000-000000000001","name":"Apps","apps":[]}],
          "selectedTabID":"00000000-0000-0000-0000-000000000001",
          "hotCorner":"bottomLeft"
        }
        """.data(using: .utf8)!

        let state = try JSONDecoder().decode(LauncherState.self, from: json)

        #expect(state.hotCornerEnabled == true)
        #expect(state.hotCorner == .bottomLeft)
        #expect(state.showsDockIcon == true)
    }

    @Test func setHotCornerShowsFullscreenUpdatesState() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())

        store.setHotCornerShowsFullscreen(true)

        #expect(store.state.hotCornerShowsFullscreen == true)
        #expect(store.state.hotCornerEnabled == true)
    }

    @Test func launcherStateDecodesMissingHotCornerShowsFullscreenAsFalse() throws {
        let json = """
        {
          "tabs": [{"id":"00000000-0000-0000-0000-000000000001","name":"Apps","apps":[]}],
          "selectedTabID":"00000000-0000-0000-0000-000000000001",
          "hotCorner":"bottomLeft",
          "hotCornerEnabled":true
        }
        """.data(using: .utf8)!

        let state = try JSONDecoder().decode(LauncherState.self, from: json)

        #expect(state.hotCornerShowsFullscreen == false)
    }

    @Test func hotCornerShowsFullscreenPersistsAndReloads() {
        let persistence = InMemoryLauncherPersistence()
        let store = LauncherStore(persistence: persistence)

        store.setHotCornerShowsFullscreen(true)
        let reloaded = LauncherStore(persistence: persistence)

        #expect(reloaded.state.hotCornerShowsFullscreen == true)
    }

    @Test func setShowsDockIconUpdatesState() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())

        store.setShowsDockIcon(false)

        #expect(store.state.showsDockIcon == false)
    }

    @Test func launcherStateDecodesMissingShowsDockIconAsTrue() throws {
        let json = """
        {
          "tabs": [{"id":"00000000-0000-0000-0000-000000000001","name":"Apps","apps":[]}],
          "selectedTabID":"00000000-0000-0000-0000-000000000001",
          "hotCorner":"bottomLeft",
          "hotCornerEnabled":true
        }
        """.data(using: .utf8)!

        let state = try JSONDecoder().decode(LauncherState.self, from: json)

        #expect(state.showsDockIcon == true)
    }

    @Test func mutationsPersistAndReloadRestoresState() throws {
        let persistence = InMemoryLauncherPersistence()
        let store = LauncherStore(persistence: persistence)
        let work = store.addTab(name: "Work")
        _ = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/Xcode.app"), displayName: "Xcode")
        store.setHotCorner(.topLeft)
        store.setHotCornerEnabled(false)
        store.setShowsDockIcon(false)
        store.selectTab(id: work.id)

        let reloaded = LauncherStore(persistence: persistence)

        #expect(reloaded.state.tabs.count == 2)
        #expect(reloaded.state.tabs[1].name == "Work")
        #expect(reloaded.state.tabs[1].apps.count == 1)
        #expect(reloaded.state.tabs[1].apps[0].bundlePath == "/Applications/Xcode.app")
        #expect(reloaded.state.hotCorner == .topLeft)
        #expect(reloaded.state.hotCornerEnabled == false)
        #expect(reloaded.state.showsDockIcon == false)
        #expect(reloaded.state.selectedTabID == work.id)
    }

    @Test func selectedTabReturnsCurrentlySelectedTab() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let work = store.addTab(name: "Work")

        #expect(store.selectedTab?.id == work.id)
        #expect(store.selectedTab?.name == "Work")
    }

    @Test func destinationTabsExcludesTabThatOwnsTheApp() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let sourceID = store.state.tabs[0].id
        let app = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/Mail.app"), displayName: "Mail")
        let work = store.addTab(name: "Work")
        let personal = store.addTab(name: "Personal")

        let destinations = store.destinationTabs(forAppID: app.id)

        #expect(destinations.map(\.id) == [work.id, personal.id])
        #expect(!destinations.contains(where: { $0.id == sourceID }))
    }

    @Test func destinationTabsIsEmptyWhenAppIDIsUnknown() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        _ = store.addTab(name: "Work")

        let destinations = store.destinationTabs(forAppID: UUID())

        #expect(destinations.isEmpty)
    }

    @Test func reorderAppMovesFirstAppToEnd() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let first = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/A.app"), displayName: "A")
        let second = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/B.app"), displayName: "B")
        let third = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/C.app"), displayName: "C")

        store.reorderApp(id: first.id, toIndex: 2)

        #expect(store.state.tabs[0].apps.map(\.id) == [second.id, third.id, first.id])
    }

    @Test func reorderAppMovesLastAppToFront() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let first = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/A.app"), displayName: "A")
        let second = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/B.app"), displayName: "B")
        let third = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/C.app"), displayName: "C")

        store.reorderApp(id: third.id, toIndex: 0)

        #expect(store.state.tabs[0].apps.map(\.id) == [third.id, first.id, second.id])
    }

    @Test func reorderAppIgnoresUnknownID() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let first = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/A.app"), displayName: "A")
        let second = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/B.app"), displayName: "B")
        let orderBefore = store.state.tabs[0].apps.map(\.id)

        store.reorderApp(id: UUID(), toIndex: 0)

        #expect(store.state.tabs[0].apps.map(\.id) == orderBefore)
        #expect(store.state.tabs[0].apps.map(\.id) == [first.id, second.id])
    }

    @Test func reorderAppIgnoresOutOfRangeIndex() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let first = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/A.app"), displayName: "A")
        let second = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/B.app"), displayName: "B")
        let orderBefore = store.state.tabs[0].apps.map(\.id)

        store.reorderApp(id: first.id, toIndex: -1)
        #expect(store.state.tabs[0].apps.map(\.id) == orderBefore)

        store.reorderApp(id: first.id, toIndex: 2)
        #expect(store.state.tabs[0].apps.map(\.id) == orderBefore)
        #expect(store.state.tabs[0].apps.map(\.id) == [first.id, second.id])
    }

    @Test func reorderAppPersistsOrder() throws {
        let persistence = InMemoryLauncherPersistence()
        let store = LauncherStore(persistence: persistence)
        let first = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/A.app"), displayName: "A")
        let second = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/B.app"), displayName: "B")
        let third = store.registerApp(bundleURL: URL(fileURLWithPath: "/Applications/C.app"), displayName: "C")

        store.reorderApp(id: first.id, toIndex: 2)

        let reloaded = LauncherStore(persistence: persistence)
        #expect(reloaded.state.tabs[0].apps.map(\.id) == [second.id, third.id, first.id])
    }

    @Test func reorderTabMovesFirstTabToEnd() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let firstID = store.state.tabs[0].id
        let second = store.addTab(name: "Work")
        let third = store.addTab(name: "Personal")

        store.reorderTab(id: firstID, toIndex: 2)

        #expect(store.state.tabs.map(\.id) == [second.id, third.id, firstID])
        #expect(store.state.selectedTabID == third.id)
    }

    @Test func reorderTabMovesLastTabToFront() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let firstID = store.state.tabs[0].id
        let second = store.addTab(name: "Work")
        let third = store.addTab(name: "Personal")

        store.reorderTab(id: third.id, toIndex: 0)

        #expect(store.state.tabs.map(\.id) == [third.id, firstID, second.id])
        #expect(store.state.selectedTabID == third.id)
    }

    @Test func reorderTabIgnoresUnknownID() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let firstID = store.state.tabs[0].id
        let second = store.addTab(name: "Work")
        let orderBefore = store.state.tabs.map(\.id)

        store.reorderTab(id: UUID(), toIndex: 0)

        #expect(store.state.tabs.map(\.id) == orderBefore)
        #expect(store.state.tabs.map(\.id) == [firstID, second.id])
    }

    @Test func reorderTabIgnoresOutOfRangeIndex() {
        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let firstID = store.state.tabs[0].id
        let second = store.addTab(name: "Work")
        let orderBefore = store.state.tabs.map(\.id)

        store.reorderTab(id: firstID, toIndex: -1)
        #expect(store.state.tabs.map(\.id) == orderBefore)

        store.reorderTab(id: firstID, toIndex: 2)
        #expect(store.state.tabs.map(\.id) == orderBefore)
        #expect(store.state.tabs.map(\.id) == [firstID, second.id])
    }

    @Test func reorderTabPersistsOrder() throws {
        let persistence = InMemoryLauncherPersistence()
        let store = LauncherStore(persistence: persistence)
        let firstID = store.state.tabs[0].id
        let second = store.addTab(name: "Work")
        let third = store.addTab(name: "Personal")

        store.reorderTab(id: firstID, toIndex: 2)

        let reloaded = LauncherStore(persistence: persistence)
        #expect(reloaded.state.tabs.map(\.id) == [second.id, third.id, firstID])
    }
}
