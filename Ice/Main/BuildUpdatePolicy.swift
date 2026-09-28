//
//  BuildUpdatePolicy.swift
//  Ice
//

import Foundation

enum BuildUpdatePolicy {
    static func allowsUpstreamUpdates(info: [String: Any]) -> Bool {
        info["IceDisableUpstreamUpdates"] as? Bool != true
    }
}
