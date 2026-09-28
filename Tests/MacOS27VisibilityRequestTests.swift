import Foundation

@main
enum MacOS27VisibilityRequestTests {
    static func main() {
        var request = MacOS27VisibilityRequest()
        precondition(!request.permitsBoundaryDrag(at: 1))
        request.begin(origin: .button, at: 10)
        let hiding = request.generation
        precondition(request.permitsBoundaryDrag(at: 10.1))
        request.begin(origin: .automatic, at: 10.25)
        precondition(!request.isCurrent(hiding))
        precondition(!request.permitsBoundaryDrag(at: 10.3))
        request.begin(origin: .scroll, at: 11)
        precondition(request.permitsBoundaryDrag(at: 11.1))
        let scrolling = request.generation
        request.begin(origin: .button, at: 11.2)
        precondition(!request.isCurrent(scrolling))
        precondition(request.isCurrent(request.generation))
        precondition(!request.permitsBoundaryDrag(at: 10))
        precondition(!request.permitsBoundaryDrag(at: 14.2))
        let pendingCheck = request.generation
        request.invalidate()
        precondition(!request.isCurrent(pendingCheck))
        print("10 visibility request assertions passed")
    }
}
