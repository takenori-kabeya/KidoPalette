//
//  LauncherOverlayPolicyTests.swift
//  KidoPaletteTests
//

import CoreGraphics
import Testing
@testable import KidoPalette

struct LauncherOverlayPolicyTests {

    @Test func transitionDurationIsPerceptibleButShort() {
        #expect(LauncherOverlayPolicy.transitionDuration >= 0.2)
        #expect(LauncherOverlayPolicy.transitionDuration <= 0.4)
    }

    @Test func suspendsWhenAuxiliaryWindowBecomesKeyDuringFullscreenOverlay() {
        #expect(
            LauncherOverlayPolicy.shouldSuspendOverlay(
                isVisible: true,
                showsFullscreen: true,
                isAlreadySuspended: false,
                keyWindowIsLauncher: false
            )
        )
    }

    @Test func doesNotSuspendWhenAlreadySuspendedOrNotFullscreen() {
        #expect(
            !LauncherOverlayPolicy.shouldSuspendOverlay(
                isVisible: true,
                showsFullscreen: true,
                isAlreadySuspended: true,
                keyWindowIsLauncher: false
            )
        )
        #expect(
            !LauncherOverlayPolicy.shouldSuspendOverlay(
                isVisible: true,
                showsFullscreen: false,
                isAlreadySuspended: false,
                keyWindowIsLauncher: false
            )
        )
        #expect(
            !LauncherOverlayPolicy.shouldSuspendOverlay(
                isVisible: true,
                showsFullscreen: true,
                isAlreadySuspended: false,
                keyWindowIsLauncher: true
            )
        )
    }

    @Test func resumesWhenLauncherBecomesKeyAfterSuspend() {
        #expect(
            LauncherOverlayPolicy.shouldResumeOverlay(
                isVisible: true,
                showsFullscreen: true,
                isSuspended: true,
                keyWindowIsLauncher: true
            )
        )
        #expect(
            !LauncherOverlayPolicy.shouldResumeOverlay(
                isVisible: true,
                showsFullscreen: true,
                isSuspended: true,
                keyWindowIsLauncher: false
            )
        )
        #expect(
            !LauncherOverlayPolicy.shouldResumeOverlay(
                isVisible: false,
                showsFullscreen: true,
                isSuspended: true,
                keyWindowIsLauncher: true
            )
        )
    }

    @Test func centeredFrameKeepsSizeOnCoveringScreenEvenIfSavedFrameWasElsewhere() {
        let savedSize = CGSize(width: 800, height: 560)
        // 座標の大きい／別スクリーン側に残っていたウィンドウサイズを、
        // いま覆っているスクリーン中央へ移す。
        let covering = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let result = LauncherOverlayPolicy.centeredFrame(size: savedSize, in: covering)

        #expect(result.width == savedSize.width)
        #expect(result.height == savedSize.height)
        #expect(abs(result.midX - covering.midX) < 0.5)
        #expect(abs(result.midY - covering.midY) < 0.5)
    }

    @Test func centeredFrameClampsIntoScreenWhenLargerThanScreen() {
        let covering = CGRect(x: 0, y: 0, width: 800, height: 600)
        let result = LauncherOverlayPolicy.centeredFrame(
            size: CGSize(width: 1200, height: 900),
            in: covering
        )
        #expect(result.width <= covering.width)
        #expect(result.height <= covering.height)
        #expect(result.minX >= covering.minX)
        #expect(result.maxX <= covering.maxX)
        #expect(result.minY >= covering.minY)
        #expect(result.maxY <= covering.maxY)
    }

    @Test func centersOnlySettingsWindowWhileLauncherIsVisible() {
        #expect(
            LauncherOverlayPolicy.shouldCenterAuxiliaryWindow(
                isLauncherVisible: true,
                keyWindowIsLauncher: false,
                windowIdentifier: LauncherOverlayPolicy.settingsWindowIdentifier
            )
        )
    }

    @Test func doesNotCenterHelpAboutOrUnidentifiedWindows() {
        #expect(
            !LauncherOverlayPolicy.shouldCenterAuxiliaryWindow(
                isLauncherVisible: true,
                keyWindowIsLauncher: false,
                windowIdentifier: "help"
            )
        )
        #expect(
            !LauncherOverlayPolicy.shouldCenterAuxiliaryWindow(
                isLauncherVisible: true,
                keyWindowIsLauncher: false,
                windowIdentifier: "about"
            )
        )
        #expect(
            !LauncherOverlayPolicy.shouldCenterAuxiliaryWindow(
                isLauncherVisible: true,
                keyWindowIsLauncher: false,
                windowIdentifier: nil
            )
        )
    }

    @Test func doesNotCenterWhenLauncherHiddenOrKeyIsLauncher() {
        #expect(
            !LauncherOverlayPolicy.shouldCenterAuxiliaryWindow(
                isLauncherVisible: false,
                keyWindowIsLauncher: false,
                windowIdentifier: LauncherOverlayPolicy.settingsWindowIdentifier
            )
        )
        #expect(
            !LauncherOverlayPolicy.shouldCenterAuxiliaryWindow(
                isLauncherVisible: true,
                keyWindowIsLauncher: true,
                windowIdentifier: LauncherOverlayPolicy.settingsWindowIdentifier
            )
        )
    }
}
