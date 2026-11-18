//
//  LauncherReorderDragItemTests.swift
//  KidoPaletteTests
//

import CoreGraphics
import Foundation
import Testing
@testable import KidoPalette

struct LauncherReorderDragItemTests {

    @Test func insertionIndexHitsExpandedGapFrame() {
        let frames: [Int: CGRect] = [
            0: CGRect(x: 0, y: 0, width: 28, height: 104),
            1: CGRect(x: 120, y: 0, width: 28, height: 104),
            2: CGRect(x: 240, y: 0, width: 28, height: 104)
        ]
        #expect(
            LauncherReorderGeometry.insertionIndex(
                containing: CGPoint(x: 130, y: 50),
                frames: frames
            ) == 1
        )
    }

    @Test func insertionIndexReturnsNilWhenFarFromAllGaps() {
        let frames: [Int: CGRect] = [
            0: CGRect(x: 0, y: 0, width: 28, height: 104)
        ]
        #expect(
            LauncherReorderGeometry.insertionIndex(
                containing: CGPoint(x: 900, y: 900),
                frames: frames
            ) == nil
        )
    }

    @Test func insertionIndexPicksNearestNearbyGap() {
        let frames: [Int: CGRect] = [
            0: CGRect(x: 0, y: 0, width: 28, height: 104),
            1: CGRect(x: 200, y: 0, width: 28, height: 104)
        ]
        #expect(
            LauncherReorderGeometry.insertionIndex(
                containing: CGPoint(x: 40, y: 40),
                frames: frames
            ) == 0
        )
    }
}
