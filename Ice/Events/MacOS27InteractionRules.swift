//
//  MacOS27InteractionRules.swift
//  Ice
//

import CoreGraphics

enum MacOS27InteractionRules {
    enum ScrollAction {
        case show, hide
    }

    static func scrollAction(
        deltaX: CGFloat, deltaY: CGFloat, point: CGPoint,
        display: CGRect, control: CGRect, suppressed: Bool
    ) -> ScrollAction? {
        guard !suppressed, deltaX.isFinite, deltaY.isFinite,
              MacOS27MenuBarGeometry.isOnMenuBar(control, display: display) else { return nil }
        let strip = CGRect(x: display.minX, y: display.minY, width: display.width,
                           height: min(40, control.maxY - display.minY + 2))
        guard strip.contains(point) else { return nil }
        // Preserve Ice's existing direction and strict per-event threshold.
        let average = (deltaX + deltaY) / 2
        if average > 5 { return .show }
        if average < -5 { return .hide }
        return nil
    }
}
