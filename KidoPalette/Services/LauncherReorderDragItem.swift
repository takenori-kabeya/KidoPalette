//
//  LauncherReorderDragItem.swift
//  KidoPalette
//

import CoreGraphics
import Foundation

/// アプリ内並べ替え用の幾何ユーティリティ。
/// システムペーストボードを使わないことで、デスクトップへのファイル生成を防ぐ。
nonisolated enum LauncherReorderGeometry {
    /// ポインタ位置に対応する挿入ギャップ index を返す。
    static func insertionIndex(
        containing point: CGPoint,
        frames: [Int: CGRect],
        hitSlop: CGSize = CGSize(width: 8, height: 24)
    ) -> Int? {
        let expandedHits = frames.map { index, frame -> (Int, CGRect) in
            let rect = frame.insetBy(dx: -hitSlop.width, dy: -hitSlop.height)
            return (index, rect)
        }
        if let exact = expandedHits.first(where: { $0.1.contains(point) })?.0 {
            return exact
        }

        // ギャップ直上でなくても、近くにあればそのギャップを選ぶ（グリッド内ドラッグ用）。
        let nearest = frames.min { lhs, rhs in
            distance(point, lhs.value) < distance(point, rhs.value)
        }
        guard let nearest else { return nil }
        let limit = max(nearest.value.width, nearest.value.height) * 2.5
        guard distance(point, nearest.value) <= limit else { return nil }
        return nearest.key
    }

    private static func distance(_ point: CGPoint, _ rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return hypot(dx, dy)
    }
}
