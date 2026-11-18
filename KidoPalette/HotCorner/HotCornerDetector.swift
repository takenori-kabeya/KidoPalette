//
//  HotCornerDetector.swift
//  KidoPalette
//

import CoreGraphics
import Foundation

enum HotCornerDetector {
    /// Uses AppKit/Quartz screen coordinates where origin is bottom-left.
    static func shouldTrigger(
        point: CGPoint,
        screen: CGRect,
        corner: HotCorner,
        threshold: CGFloat
    ) -> Bool {
        let minX = screen.minX
        let maxX = screen.maxX
        let minY = screen.minY
        let maxY = screen.maxY

        switch corner {
        case .bottomLeft:
            return point.x >= minX && point.x <= minX + threshold
                && point.y >= minY && point.y <= minY + threshold
        case .bottomRight:
            return point.x >= maxX - threshold && point.x <= maxX
                && point.y >= minY && point.y <= minY + threshold
        case .topLeft:
            return point.x >= minX && point.x <= minX + threshold
                && point.y >= maxY - threshold && point.y <= maxY
        case .topRight:
            return point.x >= maxX - threshold && point.x <= maxX
                && point.y >= maxY - threshold && point.y <= maxY
        }
    }
}
