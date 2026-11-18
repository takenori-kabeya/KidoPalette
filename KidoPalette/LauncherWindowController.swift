//
//  LauncherWindowController.swift
//  KidoPalette
//

import AppKit
import CoreGraphics
import Foundation

enum LauncherOverlayPolicy {
    /// フルスクリーン退避／復帰のフレーム補間時間。
    static let transitionDuration: TimeInterval = 0.28

    /// Settings ウィンドウの `NSWindow.identifier`（中央寄せ対象）。
    static let settingsWindowIdentifier = "settings"

    /// フルスクリーンオーバーレイ中にランチャー以外がキーになったら、設定等の背面隠れを避けるため退避する。
    static func shouldSuspendOverlay(
        isVisible: Bool,
        showsFullscreen: Bool,
        isAlreadySuspended: Bool,
        keyWindowIsLauncher: Bool
    ) -> Bool {
        isVisible && showsFullscreen && !isAlreadySuspended && !keyWindowIsLauncher
    }

    /// 退避中にランチャーが再びキーになったらオーバーレイを再開する。
    static func shouldResumeOverlay(
        isVisible: Bool,
        showsFullscreen: Bool,
        isSuspended: Bool,
        keyWindowIsLauncher: Bool
    ) -> Bool {
        isVisible && showsFullscreen && isSuspended && keyWindowIsLauncher
    }

    /// ランチャー表示中に Settings だけをグリッドのあるスクリーン中央へ寄せる。
    /// Help / About / Open パネルなどはシステムの既定位置のままにする。
    static func shouldCenterAuxiliaryWindow(
        isLauncherVisible: Bool,
        keyWindowIsLauncher: Bool,
        windowIdentifier: String?
    ) -> Bool {
        isLauncherVisible
            && !keyWindowIsLauncher
            && windowIdentifier == settingsWindowIdentifier
    }

    /// 保存済みサイズを、いまグリッドがいるスクリーン中央へ置く（マルチディスプレイ対策）。
    static func centeredFrame(size: CGSize, in screenFrame: CGRect) -> CGRect {
        let width = min(max(size.width, 200), screenFrame.width)
        let height = min(max(size.height, 200), screenFrame.height)
        return CGRect(
            x: screenFrame.midX - width / 2,
            y: screenFrame.midY - height / 2,
            width: width,
            height: height
        )
    }
}

@MainActor
final class LauncherController {
    private let monitor: HotCornerMonitor
    private let showsFullscreen: () -> Bool
    private struct WindowPresentation {
        var frame: NSRect
        var styleMask: NSWindow.StyleMask
    }

    private var presentationBeforeFullscreen: [ObjectIdentifier: WindowPresentation] = [:]
    /// いまフルスクリーンで覆っているスクリーン（マルチディスプレイ時の退避／設定配置の基準）。
    private var overlayScreenFrame: NSRect?
    private var isOverlaySuspended = false
    private var overlayTransitionID = UUID()
    private var keyWindowObserver: NSObjectProtocol?
    private var windowCloseObserver: NSObjectProtocol?
    private(set) var isVisible = true

    /// Menu bar / Dock より手前に出すためのレベル（スクリーンシールド相当）。
    private static let overlayLevel = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))

    init(store: LauncherStore) {
        self.showsFullscreen = { store.state.hotCornerShowsFullscreen }
        self.monitor = HotCornerMonitor(
            cornerProvider: { store.state.hotCorner },
            isEnabledProvider: { store.state.hotCornerEnabled }
        )
        self.monitor.onTrigger = { [weak self] in
            self?.toggleVisibility()
        }
    }

    func start() {
        monitor.start()
        guard keyWindowObserver == nil else { return }
        keyWindowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // queue: .main。weak を let に束縛してから MainActor へ渡す。
            guard let self else { return }
            let window = notification.object as? NSWindow
            Task { @MainActor in
                self.handleWindowDidBecomeKey(window)
            }
        }
        windowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let window = notification.object as? NSWindow
            Task { @MainActor in
                self.handleWindowWillClose(window)
            }
        }
    }

    func stop() {
        monitor.stop()
        if let keyWindowObserver {
            NotificationCenter.default.removeObserver(keyWindowObserver)
            self.keyWindowObserver = nil
        }
        if let windowCloseObserver {
            NotificationCenter.default.removeObserver(windowCloseObserver)
            self.windowCloseObserver = nil
        }
    }

    func toggleVisibility() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        isVisible = true
        isOverlaySuspended = false
        overlayTransitionID = UUID()
        let fullscreen = showsFullscreen()
        NSApp.activate(ignoringOtherApps: true)
        for window in launcherWindows() {
            if fullscreen {
                window.level = Self.overlayLevel
                // ホットコーナー表示は即時。アニメーションは設定等の退避／復帰のみ。
                coverScreen(window, animated: false)
            } else {
                // Xcode などフォーカスを渡しにくい前面アプリでも見えるよう、
                // 一時的に floating で上げつつ orderFrontRegardless する。
                // 設定ウィンドウ等を覆い続けないよう、前面化後は通常レベルへ戻す。
                window.level = .floating
                overlayScreenFrame = window.screen?.frame ?? window.frame
            }
            window.collectionBehavior.insert([.moveToActiveSpace, .fullScreenAuxiliary])
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
        }
        if !fullscreen {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard isVisible, !showsFullscreen(), !isOverlaySuspended else { return }
                for window in launcherWindows() {
                    window.level = .normal
                }
            }
        }
    }

    func hide() {
        isVisible = false
        isOverlaySuspended = false
        overlayTransitionID = UUID()
        overlayScreenFrame = nil
        for window in launcherWindows() {
            window.level = .normal
            restoreFrame(window)
            window.orderOut(nil)
        }
    }

    private func handleWindowDidBecomeKey(_ window: NSWindow?) {
        guard let window else { return }
        let keyWindowIsLauncher = isLauncherWindow(window)

        // Settings だけ、グリッドがあるスクリーン中央へ寄せる。
        centerAuxiliaryWindowIfNeeded(window, keyWindowIsLauncher: keyWindowIsLauncher)
        // WindowAccessor が identifier を後から付ける場合に備え、次ターンでも再判定する。
        if !keyWindowIsLauncher, isVisible, window.identifier == nil {
            Task { @MainActor [weak self] in
                self?.centerAuxiliaryWindowIfNeeded(window, keyWindowIsLauncher: false)
            }
        }

        if LauncherOverlayPolicy.shouldSuspendOverlay(
            isVisible: isVisible,
            showsFullscreen: showsFullscreen(),
            isAlreadySuspended: isOverlaySuspended,
            keyWindowIsLauncher: keyWindowIsLauncher
        ) {
            suspendOverlay()
            return
        }
        if LauncherOverlayPolicy.shouldResumeOverlay(
            isVisible: isVisible,
            showsFullscreen: showsFullscreen(),
            isSuspended: isOverlaySuspended,
            keyWindowIsLauncher: keyWindowIsLauncher
        ) {
            resumeOverlay()
        }
    }

    private func handleWindowWillClose(_ window: NSWindow?) {
        guard let window, !isLauncherWindow(window), isOverlaySuspended else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000)
            guard isOverlaySuspended, isVisible, showsFullscreen() else { return }
            let auxiliaryStillOpen = NSApp.windows.contains {
                $0.isVisible && !isLauncherWindow($0)
            }
            if !auxiliaryStillOpen {
                resumeOverlay()
            }
        }
    }

    /// 設定・ヘルプ・Open パネルなどが前面に出られるよう、シールドオーバーレイを一時解除する。
    private func suspendOverlay() {
        isOverlaySuspended = true
        let transitionID = UUID()
        overlayTransitionID = transitionID
        let coveringFrame = overlayScreenFrame
            ?? launcherWindows().first.flatMap { screenFrameContaining($0.frame) }
        for window in launcherWindows() {
            window.level = .normal
            let id = ObjectIdentifier(window)
            guard let presentation = presentationBeforeFullscreen[id] else { continue }
            let targetScreen = coveringFrame
                ?? screenFrameContaining(presentation.frame)
                ?? presentation.frame
            let target = LauncherOverlayPolicy.centeredFrame(
                size: presentation.frame.size,
                in: targetScreen
            )
            // 以降の restore も同じスクリーンに残す。
            presentationBeforeFullscreen[id] = WindowPresentation(
                frame: target,
                styleMask: presentation.styleMask
            )
            let styleMask = presentation.styleMask
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.animateFrame(window, to: target)
                guard self.overlayTransitionID == transitionID, self.isOverlaySuspended else { return }
                window.styleMask = styleMask
            }
        }
    }

    private func resumeOverlay() {
        isOverlaySuspended = false
        guard isVisible, showsFullscreen() else { return }
        overlayTransitionID = UUID()
        for window in launcherWindows() {
            window.level = Self.overlayLevel
            window.collectionBehavior.insert([.moveToActiveSpace, .fullScreenAuxiliary])
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
            // 退避前と同じスクリーンへ戻す（マウス位置に引っ張られないようにする）。
            coverScreen(window, animated: true, preferredScreenFrame: overlayScreenFrame)
        }
    }

    private func coverScreen(
        _ window: NSWindow,
        animated: Bool,
        preferredScreenFrame: NSRect? = nil
    ) {
        guard let screenFrame = preferredScreenFrame ?? screenFrameForCovering(window) else { return }
        overlayScreenFrame = screenFrame
        let id = ObjectIdentifier(window)
        if presentationBeforeFullscreen[id] == nil {
            presentationBeforeFullscreen[id] = WindowPresentation(
                frame: window.frame,
                styleMask: window.styleMask
            )
        }
        window.styleMask = [.borderless]
        if animated {
            Task { @MainActor [weak self] in
                await self?.animateFrame(window, to: screenFrame)
            }
        } else {
            window.setFrame(screenFrame, display: true)
        }
    }

    private func screenFrameForCovering(_ window: NSWindow) -> NSRect? {
        let point = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(point) } ?? window.screen ?? NSScreen.main
        return screen?.frame
    }

    private func screenFrameContaining(_ rect: NSRect) -> NSRect? {
        let anchor = CGPoint(x: rect.midX, y: rect.midY)
        return NSScreen.screens.first { $0.frame.contains(anchor) }?.frame
            ?? NSScreen.screens.first { $0.frame.intersects(rect) }?.frame
    }

    private func launcherScreen() -> NSScreen? {
        if let overlayScreenFrame {
            let anchor = CGPoint(x: overlayScreenFrame.midX, y: overlayScreenFrame.midY)
            if let match = NSScreen.screens.first(where: { $0.frame.contains(anchor) }) {
                return match
            }
        }
        return launcherWindows().first?.screen ?? NSScreen.main
    }

    private func centerAuxiliaryWindowIfNeeded(_ window: NSWindow, keyWindowIsLauncher: Bool) {
        guard LauncherOverlayPolicy.shouldCenterAuxiliaryWindow(
            isLauncherVisible: isVisible,
            keyWindowIsLauncher: keyWindowIsLauncher,
            windowIdentifier: window.identifier?.rawValue
        ), let screen = launcherScreen() else { return }
        center(window, on: screen)
    }

    private func center(_ window: NSWindow, on screen: NSScreen) {
        let target = LauncherOverlayPolicy.centeredFrame(
            size: window.frame.size,
            in: screen.visibleFrame
        )
        window.setFrame(target, display: true)
    }

    private func animateFrame(_ window: NSWindow, to frame: NSRect) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = LauncherOverlayPolicy.transitionDuration
                context.timingFunction = .init(name: .easeInEaseOut)
                context.allowsImplicitAnimation = true
                window.animator().setFrame(frame, display: true)
            }, completionHandler: { @Sendable in
                continuation.resume()
            })
        }
    }

    private func restoreFrame(_ window: NSWindow) {
        let id = ObjectIdentifier(window)
        guard let presentation = presentationBeforeFullscreen.removeValue(forKey: id) else { return }
        window.styleMask = presentation.styleMask
        window.setFrame(presentation.frame, display: false)
    }

    func launchAndHide(_ app: RegisteredApp) {
        _ = AppLauncher.launch(app)
        hide()
    }

    private func isLauncherWindow(_ window: NSWindow) -> Bool {
        window.identifier?.rawValue == "launcher" || window.title == "KidoPalette"
    }

    private func launcherWindows() -> [NSWindow] {
        NSApp.windows.filter(isLauncherWindow)
    }
}
