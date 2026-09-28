import Foundation

@main
enum MacOS27SmartRehideTests {
    static func main() {
        typealias Context = MacOS27InteractionRules.SmartRehideContext
        let activeWindow = Context()
        precondition(MacOS27InteractionRules.shouldSmartRehide(activeWindow))
        let exclusions: [(inout Context) -> Void] = [
            { $0.enabled = false }, { $0.hasVisibleSection = false },
            { $0.insideMenuBar = true }, { $0.settingsPresented = true },
            { $0.layoutEditing = true }, { $0.dragging = true },
            { $0.menuTracking = true }, { $0.isIce = true },
            { $0.isRegularApplication = false }, { $0.isActiveApplication = false },
            { $0.requestIsCurrent = false },
        ]
        for exclude in exclusions {
            var context = activeWindow
            exclude(&context)
            precondition(!MacOS27InteractionRules.shouldSmartRehide(context))
        }
        var dock = Context()
        dock.isDock = true
        dock.isRegularApplication = false
        dock.isActiveApplication = false
        precondition(MacOS27InteractionRules.shouldSmartRehide(dock))
        dock.menuTracking = true
        precondition(!MacOS27InteractionRules.shouldSmartRehide(dock))
        var request = MacOS27VisibilityRequest()
        request.begin(origin: .button, at: 1)
        let outsideClickRevision = request.generation
        request.begin(origin: .scroll, at: 1.1)
        var stale = activeWindow
        stale.requestIsCurrent = request.isCurrent(outsideClickRevision)
        precondition(!MacOS27InteractionRules.shouldSmartRehide(stale))
        request.begin(origin: .automatic, at: 1.25)
        precondition(!request.permitsBoundaryDrag(at: 1.3))
        print("16 smart rehide assertions passed")
    }
}
