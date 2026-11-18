//
//  HotCornerDetectorTests.swift
//  KidoPaletteTests
//

import CoreGraphics
import Testing
@testable import KidoPalette

struct HotCornerDetectorTests {

    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let threshold: CGFloat = 5

    @Test func bottomLeftCornerTriggers() {
        let point = CGPoint(x: 2, y: 2)
        let result = HotCornerDetector.shouldTrigger(
            point: point,
            screen: screen,
            corner: .bottomLeft,
            threshold: threshold
        )
        #expect(result == true)
    }

    @Test func bottomRightCornerTriggers() {
        let point = CGPoint(x: 1438, y: 2)
        let result = HotCornerDetector.shouldTrigger(
            point: point,
            screen: screen,
            corner: .bottomRight,
            threshold: threshold
        )
        #expect(result == true)
    }

    @Test func topLeftCornerTriggers() {
        let point = CGPoint(x: 1, y: 898)
        let result = HotCornerDetector.shouldTrigger(
            point: point,
            screen: screen,
            corner: .topLeft,
            threshold: threshold
        )
        #expect(result == true)
    }

    @Test func topRightCornerTriggers() {
        let point = CGPoint(x: 1439, y: 899)
        let result = HotCornerDetector.shouldTrigger(
            point: point,
            screen: screen,
            corner: .topRight,
            threshold: threshold
        )
        #expect(result == true)
    }

    @Test func centerDoesNotTriggerAnyCorner() {
        let point = CGPoint(x: 720, y: 450)
        for corner in HotCorner.allCases {
            let result = HotCornerDetector.shouldTrigger(
                point: point,
                screen: screen,
                corner: corner,
                threshold: threshold
            )
            #expect(result == false)
        }
    }

    @Test func wrongCornerDoesNotTrigger() {
        let point = CGPoint(x: 2, y: 2)
        let result = HotCornerDetector.shouldTrigger(
            point: point,
            screen: screen,
            corner: .topRight,
            threshold: threshold
        )
        #expect(result == false)
    }

    @Test func pointJustOutsideThresholdDoesNotTrigger() {
        let point = CGPoint(x: 6, y: 6)
        let result = HotCornerDetector.shouldTrigger(
            point: point,
            screen: screen,
            corner: .bottomLeft,
            threshold: threshold
        )
        #expect(result == false)
    }

    @Test func pointOnThresholdBoundaryTriggers() {
        let point = CGPoint(x: 5, y: 5)
        let result = HotCornerDetector.shouldTrigger(
            point: point,
            screen: screen,
            corner: .bottomLeft,
            threshold: threshold
        )
        #expect(result == true)
    }
}
