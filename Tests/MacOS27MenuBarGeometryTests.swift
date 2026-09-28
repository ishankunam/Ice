import CoreGraphics

@main
enum MacOS27MenuBarGeometryTests {
    static func main() {
        typealias Geometry = MacOS27MenuBarGeometry
        let msi = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let dell = CGRect(x: -1080, y: -420, width: 1080, height: 1920)
        let menus = CGRect(x: 0, y: 0, width: 300, height: 24)
        let ice = CGRect(x: 1650, y: 2, width: 24, height: 22)
        precondition(Geometry.concealingLength(control: ice, display: msi, applicationMenu: menus) == 1318)
        let portraitIce = CGRect(x: -200, y: -418, width: 24, height: 22)
        let portraitMenus = CGRect(x: -1080, y: -420, width: 300, height: 24)
        precondition(Geometry.concealingLength(control: portraitIce, display: dell, applicationMenu: portraitMenus) == 548)
        precondition(!Geometry.isOnMenuBar(ice, display: dell))
        precondition(Geometry.concealingLength(control: portraitIce, display: dell, applicationMenu: menus) == nil)
        precondition(Geometry.concealingLength(control: ice, display: msi, applicationMenu: nil) == nil)
        precondition(!Geometry.isOnMenuBar(CGRect(x: 10, y: 1090, width: 20, height: 24), display: msi))
        precondition(!Geometry.isOnMenuBar(CGRect(x: CGFloat.nan, y: 0, width: 20, height: 24), display: msi))
        precondition(!Geometry.isOnMenuBar(.zero, display: msi))
        let crowded = CGRect(x: 340, y: 2, width: 24, height: 22)
        precondition(Geometry.concealingLength(control: crowded, display: msi, applicationMenu: menus) == nil)
        let notched = CGRect(x: 0, y: 0, width: 1512, height: 982)
        let notchIce = CGRect(x: 1300, y: 4, width: 24, height: 24)
        let shortMenus = CGRect(x: 0, y: 0, width: 100, height: 32)
        precondition(Geometry.concealingLength(control: notchIce, display: notched,
                                               applicationMenu: shortMenus, notch: 720...792) == 588)
        precondition(Geometry.concealingLength(control: notchIce, display: notched,
                                               applicationMenu: menus, notch: 720...792) == nil)
        print("11 menu bar geometry assertions passed")
    }
}
