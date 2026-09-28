import Foundation

@main
enum BuildUpdatePolicyTests {
    static func main() throws {
        precondition(BuildUpdatePolicy.allowsUpstreamUpdates(info: [:]))
        precondition(BuildUpdatePolicy.allowsUpstreamUpdates(info: ["IceDisableUpstreamUpdates": false]))
        precondition(!BuildUpdatePolicy.allowsUpstreamUpdates(info: ["IceDisableUpstreamUpdates": true]))
        // Verify the actual source configuration, not only a synthetic dictionary.
        let data = try Data(contentsOf: URL(fileURLWithPath: "Ice/Resources/Info.plist"))
        let info = try PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]
        precondition(!BuildUpdatePolicy.allowsUpstreamUpdates(info: info))
        print("Build update policy: 4 checks passed")
    }
}
