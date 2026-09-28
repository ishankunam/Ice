import CoreGraphics

@main
enum MacOS27ScrollTests {
    static func main() {
        let display = CGRect(x: -1080, y: -420, width: 1080, height: 1920)
        let control = CGRect(x: -200, y: -418, width: 24, height: 22)
        func action(_ x: CGFloat, _ y: CGFloat, point: CGPoint = CGPoint(x: -400, y: -408),
                    suppressed: Bool = false, frame: CGRect? = nil) -> MacOS27InteractionRules.ScrollAction? {
            MacOS27InteractionRules.scrollAction(deltaX: x, deltaY: y, point: point,
                display: display, control: frame ?? control, suppressed: suppressed)
        }
        precondition(action(0, 12) == .show)
        precondition(action(0, -12) == .hide)
        precondition(action(12, 0) == .show)
        precondition(action(0, 10) == nil)
        precondition(action(0, -10) == nil)
        precondition(action(12, -12) == nil)
        precondition(action(0, 12, point: CGPoint(x: -400, y: -350)) == nil)
        precondition(action(0, 12, point: CGPoint(x: 100, y: 12)) == nil)
        precondition(action(0, 12, suppressed: true) == nil)
        precondition(action(.nan, 12) == nil)
        precondition(action(0, .infinity) == nil)
        precondition(action(0, 12, frame: CGRect(x: -200, y: -480, width: 24, height: 22)) == nil)
        print("12 scroll assertions passed")
    }
}
