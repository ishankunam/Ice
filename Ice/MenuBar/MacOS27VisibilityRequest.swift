//
//  MacOS27VisibilityRequest.swift
//  Ice
//

import Foundation

enum MenuBarVisibilityOrigin {
    case button
    case scroll
    case automatic
}

/// Authorization belongs to one visibility request, not a global timestamp
/// that a later automatic rehide can borrow from an unrelated click.
struct MacOS27VisibilityRequest {
    private(set) var generation: UInt64 = 0
    private var origin = MenuBarVisibilityOrigin.automatic
    private var timestamp: TimeInterval = 0

    mutating func begin(origin: MenuBarVisibilityOrigin, at time: TimeInterval) {
        invalidate()
        self.origin = origin
        timestamp = time
    }

    mutating func invalidate() {
        generation &+= 1
    }

    func permitsBoundaryDrag(at time: TimeInterval) -> Bool {
        origin != .automatic && time >= timestamp && time - timestamp < 3
    }

    func isCurrent(_ generation: UInt64) -> Bool {
        self.generation == generation
    }
}
