//
//  AppBundleDropTests.swift
//  KidoPaletteTests
//

import CoreGraphics
import Foundation
import Testing
@testable import KidoPalette

struct AppBundleDropTests {

    @Test func pointBesideLastIconIsTrailingDropZone() {
        let frame = CGRect(x: 100, y: 40, width: 80, height: 100)

        #expect(TrailingDropZone.contains(point: CGPoint(x: 200, y: 80), lastIconFrame: frame))
    }

    @Test func pointBelowLastIconIsTrailingDropZone() {
        let frame = CGRect(x: 100, y: 40, width: 80, height: 100)

        #expect(TrailingDropZone.contains(point: CGPoint(x: 120, y: 200), lastIconFrame: frame))
    }

    @Test func pointOnLastIconIsNotTrailingDropZone() {
        let frame = CGRect(x: 100, y: 40, width: 80, height: 100)

        #expect(TrailingDropZone.contains(point: CGPoint(x: 140, y: 80), lastIconFrame: frame) == false)
    }

    @Test func pointLeftOfLastIconIsNotTrailingDropZone() {
        let frame = CGRect(x: 100, y: 40, width: 80, height: 100)

        #expect(TrailingDropZone.contains(point: CGPoint(x: 40, y: 80), lastIconFrame: frame) == false)
    }

    @Test func appBundleDirectoryIsRegisterable() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KidoPaletteDrop-\(UUID().uuidString)", isDirectory: true)
        let appURL = directory.appendingPathComponent("Sample.app", isDirectory: true)
        try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(AppBundleDrop.isAppBundle(appURL) == true)
    }

    @Test func plainFileIsNotRegisterable() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KidoPaletteDrop-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("notes.txt")
        try Data("hello".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(AppBundleDrop.isAppBundle(fileURL) == false)
    }

    @Test func nonAppDirectoryIsNotRegisterable() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KidoPaletteDrop-\(UUID().uuidString)", isDirectory: true)
        let folderURL = directory.appendingPathComponent("Documents", isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(AppBundleDrop.isAppBundle(folderURL) == false)
    }

    @Test func registerAppStoresBookmarkForTemporaryAppBundle() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("KidoPaletteDrop-\(UUID().uuidString)", isDirectory: true)
        let appURL = directory.appendingPathComponent("Sample.app", isDirectory: true)
        try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = LauncherStore(persistence: InMemoryLauncherPersistence())
        let app = store.registerApp(bundleURL: appURL, displayName: "Sample")

        #expect(store.state.tabs[0].apps.count == 1)
        #expect(store.state.tabs[0].apps[0].id == app.id)
        #expect(store.state.tabs[0].apps[0].bundlePath == appURL.path)
        #expect(store.state.tabs[0].apps[0].displayName == "Sample")
        #expect(store.state.tabs[0].apps[0].bookmarkData != nil)
    }
}
