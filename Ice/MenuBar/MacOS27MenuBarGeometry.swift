//
//  MacOS27MenuBarGeometry.swift
//  Ice
//

import CoreGraphics

/// Geometry is expressed in global Quartz/Accessibility points, including
/// negative origins and portrait displays. No physical pixel dimensions.
enum MacOS27MenuBarGeometry {
    static func isOnMenuBar(_ frame: CGRect, display: CGRect) -> Bool {
        let values = [frame.origin.x, frame.origin.y, frame.width, frame.height,
                      display.origin.x, display.origin.y, display.width, display.height]
        guard values.allSatisfy(\.isFinite), frame.width > 0, frame.height > 0,
              display.width > 0, display.height > 0 else { return false }
        let strip = CGRect(x: display.minX, y: display.minY, width: display.width, height: 40)
        return strip.contains(frame)
    }

    /// Returns nil when a spacer cannot safely fit. In that case the caller
    /// must reveal the items instead of reporting successful concealment.
    static func concealingLength(
        control: CGRect,
        display: CGRect,
        applicationMenu: CGRect?,
        notch: ClosedRange<CGFloat>? = nil
    ) -> CGFloat? {
        guard isOnMenuBar(control, display: display),
              let applicationMenu, isOnMenuBar(applicationMenu, display: display) else { return nil }
        let margin: CGFloat = 32
        let menusMaxX = applicationMenu.maxX
        let length: CGFloat
        if let notch {
            guard notch.lowerBound.isFinite, notch.upperBound.isFinite,
                  notch.lowerBound >= display.minX, notch.upperBound <= display.maxX else { return nil }
            if control.minX >= notch.upperBound {
                let rightGap = control.minX - notch.upperBound
                let leftSegment = notch.lowerBound - menusMaxX - margin
                // Otherwise items would remain visible to the left of the notch.
                guard leftSegment > rightGap else { return nil }
                length = leftSegment
            } else {
                guard control.maxX <= notch.lowerBound else { return nil }
                length = control.minX - menusMaxX - margin
            }
        } else {
            length = control.minX - menusMaxX - margin
        }
        guard length.isFinite, length >= 32, length < display.width else { return nil }
        return length
    }
}
