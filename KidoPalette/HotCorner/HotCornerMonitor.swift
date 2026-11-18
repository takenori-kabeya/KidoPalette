//
//  HotCornerMonitor.swift
//  KidoPalette
//

import AppKit
import Foundation

@MainActor
final class HotCornerMonitor {
    var onTrigger: (() -> Void)?

    private var pollTask: Task<Void, Never>?
    private var cornerProvider: () -> HotCorner
    private var isEnabledProvider: () -> Bool
    private var isArmed = true
    private var cooldownTask: Task<Void, Never>?
    private let threshold: CGFloat
    private let cooldownNanoseconds: UInt64
    private let pollIntervalNanoseconds: UInt64

    init(
        cornerProvider: @escaping () -> HotCorner,
        isEnabledProvider: @escaping () -> Bool = { true },
        threshold: CGFloat = 5,
        cooldownNanoseconds: UInt64 = 800_000_000,
        pollIntervalNanoseconds: UInt64 = 50_000_000
    ) {
        self.cornerProvider = cornerProvider
        self.isEnabledProvider = isEnabledProvider
        self.threshold = threshold
        self.cooldownNanoseconds = cooldownNanoseconds
        self.pollIntervalNanoseconds = pollIntervalNanoseconds
    }

    func start() {
        stop()
        pollTask = Task { @MainActor [weak self] in
            while let self, !Task.isCancelled {
                self.evaluateCursor()
                try? await Task.sleep(nanoseconds: self.pollIntervalNanoseconds)
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        cooldownTask?.cancel()
        cooldownTask = nil
        isArmed = true
    }

    private func evaluateCursor() {
        guard isEnabledProvider() else { return }
        guard isArmed else { return }
        let point = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) ?? NSScreen.main else {
            return
        }
        let corner = cornerProvider()
        guard HotCornerDetector.shouldTrigger(
            point: point,
            screen: screen.frame,
            corner: corner,
            threshold: threshold
        ) else {
            return
        }
        isArmed = false
        onTrigger?()
        cooldownTask?.cancel()
        cooldownTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: cooldownNanoseconds)
            guard !Task.isCancelled else { return }
            // Re-arm only after the cursor leaves the hot zone to avoid flicker.
            while !Task.isCancelled {
                let current = NSEvent.mouseLocation
                let stillInside: Bool
                if let screen = NSScreen.screens.first(where: { $0.frame.contains(current) }) ?? NSScreen.main {
                    stillInside = HotCornerDetector.shouldTrigger(
                        point: current,
                        screen: screen.frame,
                        corner: cornerProvider(),
                        threshold: threshold
                    )
                } else {
                    stillInside = false
                }
                if !stillInside {
                    isArmed = true
                    return
                }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }
}
