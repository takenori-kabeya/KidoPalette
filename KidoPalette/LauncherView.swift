//
//  LauncherView.swift
//  KidoPalette
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

private let launcherRootCoordinateSpace = "launcherRoot"

struct LauncherView: View {
    @Bindable var store: LauncherStore
    var onDismiss: () -> Void
    var onLaunchApp: (RegisteredApp) -> Void

    @State private var renamingTabID: UUID?
    @State private var renameText = ""
    @State private var insertionIndex: Int?
    @State private var tabInsertionIndex: Int?
    @State private var draggingAppID: UUID?
    @State private var draggingTabID: UUID?
    @State private var dragLocation: CGPoint?
    @State private var appGapFrames: [Int: CGRect] = [:]
    @State private var tabGapFrames: [Int: CGRect] = [:]
    @State private var isAppDropTargeted = false
    @State private var lastIconFrame: CGRect = .zero
    @State private var appGridViewportHeight: CGFloat = 0
    @FocusState private var isRenameFieldFocused: Bool

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 4, alignment: .top)]
    private let cellContentHeight: CGFloat = 104
    private let insertionIndicatorHeight: CGFloat = 140
    private let gapWidth: CGFloat = 28
    private let tabGapWidth: CGFloat = 28
    private let tabContentHeight: CGFloat = 40
    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            appGrid
        }
        .frame(minWidth: 640, minHeight: 420)
        .background(.ultraThinMaterial)
        .coordinateSpace(.named(launcherRootCoordinateSpace))
        .overlay {
            dragPreviewOverlay
        }
        .onExitCommand(perform: onDismiss)
    }

    @ViewBuilder
    private var dragPreviewOverlay: some View {
        if let dragLocation {
            if let draggingAppID,
               let app = store.state.tabs.flatMap(\.apps).first(where: { $0.id == draggingAppID }) {
                Image(nsImage: AppIconLoader.icon(for: app))
                    .resizable()
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
                    .position(dragLocation)
                    .allowsHitTesting(false)
            } else if let draggingTabID,
                      let tab = store.state.tabs.first(where: { $0.id == draggingTabID }) {
                Text(tab.name)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                    .position(dragLocation)
                    .allowsHitTesting(false)
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(store.state.tabs.enumerated()), id: \.element.id) { index, tab in
                        HStack(spacing: 0) {
                            tabInsertionGap(beforeIndex: index)
                            tabButton(for: tab)
                            if index == store.state.tabs.count - 1 {
                                tabInsertionGap(beforeIndex: store.state.tabs.count)
                            }
                        }
                    }
                }
                .animation(.snappy(duration: 0.25), value: store.state.tabs.map(\.id))
                .onPreferenceChange(TabGapFramesPreference.self) { tabGapFrames = $0 }
            }

            Spacer(minLength: 8)

            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }

            Button {
                addApp()
            } label: {
                Label("Add App", systemImage: "plus.app")
            }

            Button {
                let index = store.state.tabs.count + 1
                _ = store.addTab(name: String(localized: "Tab \(index)"))
            } label: {
                Label("Add Tab", systemImage: "plus")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func tabButton(for tab: AppTab) -> some View {
        let isSelected = store.state.selectedTabID == tab.id

        if renamingTabID == tab.id {
            TextField("Tab Name", text: $renameText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
                .focused($isRenameFieldFocused)
                .onAppear {
                    isRenameFieldFocused = true
                }
                .onSubmit {
                    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    store.renameTab(id: tab.id, name: trimmed.isEmpty ? tab.name : trimmed)
                    renamingTabID = nil
                }
        } else {
            Button {
                store.selectTab(id: tab.id)
            } label: {
                Text(tab.name)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isSelected ? Color.accentColor.opacity(0.25) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(draggingTabID == tab.id ? 0.45 : 1)
            .simultaneousGesture(
                TapGesture(count: 2).onEnded {
                    store.selectTab(id: tab.id)
                    renamingTabID = tab.id
                    renameText = tab.name
                }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .named(launcherRootCoordinateSpace))
                    .onChanged { value in
                        draggingTabID = tab.id
                        dragLocation = value.location
                        tabInsertionIndex = LauncherReorderGeometry.insertionIndex(
                            containing: value.location,
                            frames: tabGapFrames
                        )
                    }
                    .onEnded { _ in
                        if let draggingTabID, let tabInsertionIndex {
                            reorderTabDragging(draggingTabID, beforeIndex: tabInsertionIndex)
                        }
                        draggingTabID = nil
                        dragLocation = nil
                        self.tabInsertionIndex = nil
                    }
            )
            .contextMenu {
                Button("Rename") {
                    renamingTabID = tab.id
                    renameText = tab.name
                }
                Button("Delete Tab", role: .destructive) {
                    store.deleteTab(id: tab.id)
                }
                .disabled(store.state.tabs.count <= 1)
            }
        }
    }

    private func tabInsertionGap(beforeIndex: Int) -> some View {
        let isActive = tabInsertionIndex == beforeIndex

        return ZStack {
            Color.clear
                .frame(width: tabGapWidth, height: tabContentHeight)

            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.accentColor)
                .frame(width: 3, height: 28)
                .opacity(isActive ? 1 : 0)
        }
        .contentShape(Rectangle())
        .background {
            GeometryReader { geo in
                Color.clear.preference(
                    key: TabGapFramesPreference.self,
                    value: [beforeIndex: geo.frame(in: .named(launcherRootCoordinateSpace))]
                )
            }
        }
    }

    private var appGrid: some View {
        Group {
            if let tab = store.selectedTab, !tab.apps.isEmpty {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(Array(tab.apps.enumerated()), id: \.element.id) { index, app in
                            HStack(spacing: 0) {
                                insertionGap(beforeIndex: index)
                                appCell(app)
                            }
                            .overlay(alignment: .trailing) {
                                if index == tab.apps.count - 1 {
                                    insertionGap(beforeIndex: tab.apps.count)
                                        .offset(x: gapWidth)
                                }
                            }
                            .background {
                                if index == tab.apps.count - 1 {
                                    GeometryReader { geo in
                                        Color.clear.preference(
                                            key: LastIconFramePreference.self,
                                            value: geo.frame(in: .named("launcherAppGrid"))
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .animation(.snappy(duration: 0.25), value: tab.apps.map(\.id))
                    .padding(24)
                    .frame(maxWidth: .infinity, minHeight: appGridViewportHeight, alignment: .topLeading)
                    .coordinateSpace(.named("launcherAppGrid"))
                    .contentShape(Rectangle())
                    .onDrop(
                        of: [.fileURL],
                        delegate: TrailingSpaceDropDelegate(
                            endIndex: tab.apps.count,
                            lastIconFrame: lastIconFrame,
                            insertionIndex: $insertionIndex,
                            onRegisterFiles: { index, providers in
                                registerDroppedApps(providers, at: index)
                            }
                        )
                    )
                    .onPreferenceChange(LastIconFramePreference.self) { frame in
                        lastIconFrame = frame
                    }
                    .onPreferenceChange(AppGapFramesPreference.self) { appGapFrames = $0 }
                }
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    appGridViewportHeight = height
                }
            } else {
                ContentUnavailableView(
                    "No Apps",
                    systemImage: "app.dashed",
                    description: Text("Add apps using Add App, or drop them from Finder.")
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor, lineWidth: 2)
                        .padding(8)
                        .opacity(isAppDropTargeted ? 1 : 0)
                        .allowsHitTesting(false)
                }
                .onDrop(of: [.fileURL], isTargeted: $isAppDropTargeted) { providers in
                    registerDroppedApps(providers, at: store.selectedTab?.apps.count ?? 0)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func insertionGap(beforeIndex: Int) -> some View {
        let isActive = insertionIndex == beforeIndex

        return Color.clear
            .frame(width: gapWidth, height: cellContentHeight)
            .overlay {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.accentColor)
                    .frame(width: 3, height: insertionIndicatorHeight)
                    .opacity(isActive ? 1 : 0)
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .background {
                GeometryReader { geo in
                    Color.clear.preference(
                        key: AppGapFramesPreference.self,
                        value: [beforeIndex: geo.frame(in: .named(launcherRootCoordinateSpace))]
                    )
                }
            }
            .onDrop(
                of: [.fileURL],
                delegate: ReorderDropDelegate(
                    beforeIndex: beforeIndex,
                    insertionIndex: $insertionIndex,
                    onRegisterFiles: { index, providers in
                        registerDroppedApps(providers, at: index)
                    }
                )
            )
    }

    private func appCell(_ app: RegisteredApp) -> some View {
        LauncherAppIconCell(
            app: app,
            destinationTabs: store.destinationTabs(forAppID: app.id),
            isDragging: draggingAppID == app.id,
            onLaunch: { onLaunchApp(app) },
            onMoveToTab: { store.moveApp(id: app.id, toTabID: $0) },
            onRemove: { store.removeApp(id: app.id) },
            onDragChanged: { location in
                draggingAppID = app.id
                dragLocation = location
                insertionIndex = LauncherReorderGeometry.insertionIndex(
                    containing: location,
                    frames: appGapFrames
                )
            },
            onDragEnded: {
                if let draggingAppID, let insertionIndex {
                    reorderDragging(draggingAppID, beforeIndex: insertionIndex)
                }
                draggingAppID = nil
                dragLocation = nil
                self.insertionIndex = nil
            }
        )
    }

    private func reorderDragging(_ draggedID: UUID, beforeIndex: Int) {
        guard let apps = store.selectedTab?.apps,
              let fromIndex = apps.firstIndex(where: { $0.id == draggedID })
        else {
            return
        }

        var finalIndex = beforeIndex
        if fromIndex < beforeIndex {
            finalIndex -= 1
        }
        withAnimation(.snappy(duration: 0.25)) {
            store.reorderApp(id: draggedID, toIndex: finalIndex)
        }
    }

    private func reorderTabDragging(_ draggedID: UUID, beforeIndex: Int) {
        guard let fromIndex = store.state.tabs.firstIndex(where: { $0.id == draggedID }) else {
            return
        }

        var finalIndex = beforeIndex
        if fromIndex < beforeIndex {
            finalIndex -= 1
        }
        withAnimation(.snappy(duration: 0.25)) {
            store.reorderTab(id: draggedID, toIndex: finalIndex)
        }
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = String(localized: "Choose apps to register in the launcher")
        panel.prompt = String(localized: "Add")

        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            let name = AppDisplayName.resolve(bundleURL: url)
            store.registerApp(bundleURL: url, displayName: name)
        }
    }

    @discardableResult
    private func registerDroppedApps(_ providers: [NSItemProvider], at index: Int) -> Bool {
        let typeIdentifier = UTType.fileURL.identifier
        let fileProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(typeIdentifier) }
        guard !fileProviders.isEmpty else { return false }

        let group = DispatchGroup()
        let resolved = DroppedURLBuffer(count: fileProviders.count)

        for (offset, provider) in fileProviders.enumerated() {
            group.enter()
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                let url: URL?
                if let fileURL = item as? URL {
                    url = fileURL
                } else if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else {
                    url = nil
                }
                resolved.set(url, at: offset)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            var insertion = index
            for url in resolved.snapshot() {
                guard let url else { continue }
                if registerDroppedApp(url, at: insertion) {
                    insertion += 1
                }
            }
        }
        return true
    }

    @discardableResult
    private func registerDroppedApp(_ url: URL, at index: Int) -> Bool {
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }
        guard AppBundleDrop.isAppBundle(url) else { return false }
        let name = AppDisplayName.resolve(bundleURL: url)
        store.registerApp(bundleURL: url, displayName: name, at: index)
        return true
    }
}

/// アプリアイコン。
/// マウスダウンで縮小・アップで復帰。並べ替えはペーストボードを使わず DragGesture で行う。
private struct LauncherAppIconCell: View {
    let app: RegisteredApp
    let destinationTabs: [AppTab]
    var isDragging: Bool
    var onLaunch: () -> Void
    var onMoveToTab: (UUID) -> Void
    var onRemove: () -> Void
    var onDragChanged: (CGPoint) -> Void
    var onDragEnded: () -> Void

    @State private var isPressed = false
    @State private var isLaunching = false

    /// マウスアップ後、元サイズへ戻る描画を見せてから起動する。
    private static let releaseAnimationDuration: TimeInterval = 0.14
    private static let launchDelayAfterReleaseNanoseconds: UInt64 = 160_000_000

    var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: AppIconLoader.icon(for: app))
                .resizable()
                .frame(width: 64, height: 64)
                .scaleEffect(isPressed ? 0.94 : 1.0)
                .brightness(isPressed ? -0.04 : 0)
                .shadow(
                    color: .black.opacity(isPressed ? 0.14 : 0.22),
                    radius: isPressed ? 3 : 5,
                    y: isPressed ? 1 : 3
                )
            Text(app.displayName)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80, height: 32, alignment: .top)
        }
        .padding(8)
        .opacity(isDragging ? 0.45 : 1)
        .animation(.easeOut(duration: Self.releaseAnimationDuration), value: isPressed)
        .contentShape(Rectangle())
        .background {
            // ヒットは取らず、ダウン／アップだけ見て押し込み状態を更新する。
            LauncherIconPressMonitor(isPressed: $isPressed)
        }
        .onTapGesture {
            // アップ → サイズ復帰を描画 → 起動（先に hide すると戻りが見えない）
            releaseThenLaunch()
        }
        .gesture(
            DragGesture(minimumDistance: 8, coordinateSpace: .named(launcherRootCoordinateSpace))
                .onChanged { value in
                    isPressed = false
                    onDragChanged(value.location)
                }
                .onEnded { _ in
                    onDragEnded()
                }
        )
        .onDisappear {
            isPressed = false
            isLaunching = false
        }
        .contextMenu {
            Menu("Move to Tab") {
                ForEach(destinationTabs) { tab in
                    Button(tab.name) {
                        onMoveToTab(tab.id)
                    }
                }
            }
            .disabled(destinationTabs.isEmpty)

            Button("Remove", role: .destructive) {
                onRemove()
            }
        }
    }

    private func releaseThenLaunch() {
        guard !isLaunching else { return }
        isLaunching = true
        isPressed = false
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: Self.launchDelayAfterReleaseNanoseconds)
            onLaunch()
            isLaunching = false
        }
    }
}

/// SwiftUI のジェスチャと奪い合わないよう、イベントは破棄せず監視だけする。
private struct LauncherIconPressMonitor: NSViewRepresentable {
    @Binding var isPressed: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isPressed: $isPressed)
    }

    func makeNSView(context: Context) -> LauncherIconPressMonitorView {
        let view = LauncherIconPressMonitorView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: LauncherIconPressMonitorView, context: Context) {
        context.coordinator.isPressed = $isPressed
        nsView.coordinator = context.coordinator
    }

    final class Coordinator {
        var isPressed: Binding<Bool>
        var mouseDownWindowPoint: NSPoint?

        init(isPressed: Binding<Bool>) {
            self.isPressed = isPressed
        }

        @MainActor
        func setPressed(_ pressed: Bool) {
            if isPressed.wrappedValue != pressed {
                isPressed.wrappedValue = pressed
            }
        }
    }
}

/// loadItem コールバックから安全に書き込める URL バッファ。
/// デフォルト MainActor 隔離の外で使うため、ロック付きで `@unchecked Sendable` にする。
private final class DroppedURLBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private nonisolated(unsafe) var values: [URL?]

    nonisolated init(count: Int) {
        values = Array(repeating: nil, count: count)
    }

    nonisolated func set(_ url: URL?, at index: Int) {
        lock.lock()
        values[index] = url
        lock.unlock()
    }

    nonisolated func snapshot() -> [URL?] {
        lock.lock()
        defer { lock.unlock() }
        return values
    }
}

private final class LauncherIconPressMonitorView: NSView {
    var coordinator: LauncherIconPressMonitor.Coordinator?
    /// deinit からも外せるよう MainActor 隔離の外に置く。
    private nonisolated(unsafe) var monitor: Any?
    private let dragCancelThreshold: CGFloat = 8

    override func hitTest(_ point: NSPoint) -> NSView? {
        // クリック／ドラッグは背後の SwiftUI に渡す。
        nil
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            tearDownMonitor()
            coordinator?.setPressed(false)
            coordinator?.mouseDownWindowPoint = nil
        } else {
            installMonitor()
        }
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func installMonitor() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseUp, .leftMouseDragged]
        ) { [weak self] event in
            // ローカルモニタはメインスレッドで届く。
            MainActor.assumeIsolated {
                self?.handle(event)
            }
            return event
        }
    }

    private func tearDownMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func handle(_ event: NSEvent) {
        guard let coordinator, let window, event.window == window else { return }
        let local = convert(event.locationInWindow, from: nil)

        switch event.type {
        case .leftMouseDown:
            guard bounds.contains(local) else { return }
            coordinator.mouseDownWindowPoint = event.locationInWindow
            coordinator.setPressed(true)

        case .leftMouseDragged:
            guard let start = coordinator.mouseDownWindowPoint else { return }
            let dx = event.locationInWindow.x - start.x
            let dy = event.locationInWindow.y - start.y
            if hypot(dx, dy) > dragCancelThreshold {
                // 並べ替えドラッグ開始。押し込みは解除する。
                coordinator.setPressed(false)
                coordinator.mouseDownWindowPoint = nil
            }

        case .leftMouseUp:
            guard coordinator.mouseDownWindowPoint != nil else { return }
            coordinator.setPressed(false)
            coordinator.mouseDownWindowPoint = nil

        default:
            break
        }
    }
}

private struct LastIconFramePreference: PreferenceKey {
    static let defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

private struct AppGapFramesPreference: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct TabGapFramesPreference: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct TrailingSpaceDropDelegate: DropDelegate {
    let endIndex: Int
    let lastIconFrame: CGRect
    @Binding var insertionIndex: Int?
    let onRegisterFiles: (Int, [NSItemProvider]) -> Void

    func dropEntered(info: DropInfo) {
        updateInsertion(for: info)
    }

    func dropExited(info: DropInfo) {
        if insertionIndex == endIndex {
            insertionIndex = nil
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard TrailingDropZone.contains(point: info.location, lastIconFrame: lastIconFrame) else {
            if insertionIndex == endIndex {
                insertionIndex = nil
            }
            return nil
        }
        insertionIndex = endIndex
        return DropProposal(operation: .copy)
    }

    func performDrop(info: DropInfo) -> Bool {
        let accepts = TrailingDropZone.contains(point: info.location, lastIconFrame: lastIconFrame)
        insertionIndex = nil
        guard accepts else { return false }
        let providers = info.itemProviders(for: [.fileURL])
        guard !providers.isEmpty else { return false }
        onRegisterFiles(endIndex, providers)
        return true
    }

    private func updateInsertion(for info: DropInfo) {
        if TrailingDropZone.contains(point: info.location, lastIconFrame: lastIconFrame) {
            insertionIndex = endIndex
        }
    }
}

/// Finder からの `.app` ドロップ専用（並べ替えはアプリ内 DragGesture）。
private struct ReorderDropDelegate: DropDelegate {
    let beforeIndex: Int
    @Binding var insertionIndex: Int?
    var onRegisterFiles: ((Int, [NSItemProvider]) -> Void)? = nil

    func dropEntered(info: DropInfo) {
        insertionIndex = beforeIndex
    }

    func dropExited(info: DropInfo) {
        if insertionIndex == beforeIndex {
            insertionIndex = nil
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard info.hasItemsConforming(to: [.fileURL]) else {
            return DropProposal(operation: .cancel)
        }
        return DropProposal(operation: .copy)
    }

    func performDrop(info: DropInfo) -> Bool {
        insertionIndex = nil
        let providers = info.itemProviders(for: [.fileURL])
        guard !providers.isEmpty, let onRegisterFiles else { return false }
        onRegisterFiles(beforeIndex, providers)
        return true
    }
}
