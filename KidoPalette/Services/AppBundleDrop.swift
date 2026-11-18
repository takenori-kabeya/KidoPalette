//
//  AppBundleDrop.swift
//  KidoPalette
//

import CoreGraphics
import Foundation

enum TrailingDropZone {
    static func contains(point: CGPoint, lastIconFrame: CGRect) -> Bool {
        guard lastIconFrame.width > 0, lastIconFrame.height > 0 else { return false }
        let below = point.y >= lastIconFrame.maxY - 12
        let beside = point.y >= lastIconFrame.minY - 12 && point.x >= lastIconFrame.maxX - 12
        return below || beside
    }
}

enum AppBundleDrop {
    static func isAppBundle(_ url: URL) -> Bool {
        guard url.pathExtension.lowercased() == "app" else { return false }
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
