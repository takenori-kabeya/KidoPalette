//
//  LauncherModels.swift
//  KidoPalette
//

import Foundation

/// 永続化用の純粋データ。デフォルト MainActor 隔離の対象外にする。
nonisolated enum HotCorner: String, Codable, CaseIterable, Sendable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

nonisolated struct RegisteredApp: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var bundlePath: String
    var displayName: String
    var bookmarkData: Data?
}

nonisolated struct AppTab: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var name: String
    var apps: [RegisteredApp]
}

nonisolated struct LauncherState: Codable, Equatable, Sendable {
    var tabs: [AppTab]
    var selectedTabID: UUID?
    var hotCorner: HotCorner
    var hotCornerEnabled: Bool
    var showsDockIcon: Bool
    var hotCornerShowsFullscreen: Bool

    enum CodingKeys: String, CodingKey {
        case tabs
        case selectedTabID
        case hotCorner
        case hotCornerEnabled
        case showsDockIcon
        case hotCornerShowsFullscreen
    }

    init(
        tabs: [AppTab],
        selectedTabID: UUID?,
        hotCorner: HotCorner,
        hotCornerEnabled: Bool = true,
        showsDockIcon: Bool = true,
        hotCornerShowsFullscreen: Bool = false
    ) {
        self.tabs = tabs
        self.selectedTabID = selectedTabID
        self.hotCorner = hotCorner
        self.hotCornerEnabled = hotCornerEnabled
        self.showsDockIcon = showsDockIcon
        self.hotCornerShowsFullscreen = hotCornerShowsFullscreen
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tabs = try container.decode([AppTab].self, forKey: .tabs)
        selectedTabID = try container.decodeIfPresent(UUID.self, forKey: .selectedTabID)
        hotCorner = try container.decode(HotCorner.self, forKey: .hotCorner)
        hotCornerEnabled = try container.decodeIfPresent(Bool.self, forKey: .hotCornerEnabled) ?? true
        showsDockIcon = try container.decodeIfPresent(Bool.self, forKey: .showsDockIcon) ?? true
        hotCornerShowsFullscreen = try container.decodeIfPresent(Bool.self, forKey: .hotCornerShowsFullscreen) ?? false
    }

    static func makeDefault() -> LauncherState {
        let tab = AppTab(id: UUID(), name: String(localized: "Apps"), apps: [])
        return LauncherState(
            tabs: [tab],
            selectedTabID: tab.id,
            hotCorner: .bottomLeft,
            hotCornerEnabled: true,
            showsDockIcon: true,
            hotCornerShowsFullscreen: false
        )
    }
}

protocol LauncherPersisting: Sendable {
    func load() throws -> LauncherState?
    func save(_ state: LauncherState) throws
}

final class InMemoryLauncherPersistence: LauncherPersisting, @unchecked Sendable {
    private var stored: LauncherState?
    private let lock = NSLock()

    init(stored: LauncherState? = nil) {
        self.stored = stored
    }

    func load() throws -> LauncherState? {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func save(_ state: LauncherState) throws {
        lock.lock()
        defer { lock.unlock() }
        stored = state
    }
}
