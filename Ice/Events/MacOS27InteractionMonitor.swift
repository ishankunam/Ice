//
//  MacOS27InteractionMonitor.swift
//  Ice
//

@preconcurrency import AXSwift
import Cocoa

/// Passive observers never consume native input or proxy other apps' clicks.
@MainActor
final class MacOS27InteractionMonitor {
    private weak var appState: AppState?
    private var enabled = false
    private var enabledStack = [Bool]()
    private lazy var scrollMonitor = EventMonitor.passive(for: .scrollWheel, scope: .universal) { [weak self] event in
        self?.handleScroll(event)
    }

    func performSetup(with appState: AppState) {
        self.appState = appState
        start()
    }

    func start() {
        enabled = enabledStack.popLast() ?? true
        if enabled { scrollMonitor.start() }
    }

    func stop() {
        enabledStack.append(enabled)
        enabled = false
        scrollMonitor.stop()
    }

    private func handleScroll(_ event: NSEvent) {
        guard #available(macOS 27.0, *), enabled, let appState,
              appState.settings.general.showOnScroll,
              let point = event.cgEvent?.location,
              let screen = NSScreen.screens.first(where: { CGDisplayBounds($0.displayID).contains(point) }),
              let ice = MacOS27MenuBarItemProvider.ownMenuBarItems(on: screen.displayID).first(matching: .visibleControlItem),
              ice.isOnScreen,
              isMenuBarHit(at: point),
              let hidden = appState.menuBarManager.section(withName: .hidden) else { return }
        let suppressed = appState.navigationState.isSettingsPresented ||
            appState.menuBarManager.macOS27Controller.isLayoutEditing ||
            MouseHelpers.isButtonPressed() || event.modifierFlags.contains(.command)
        guard let action = MacOS27InteractionRules.scrollAction(
            deltaX: event.scrollingDeltaX, deltaY: event.scrollingDeltaY, point: point,
            display: CGDisplayBounds(screen.displayID), control: ice.bounds, suppressed: suppressed
        ) else { return }
        switch action {
        case .show: hidden.show(origin: .scroll, screen: screen)
        case .hide: hidden.hide(origin: .scroll, screen: screen)
        }
    }

    /// Stale AX frames alone must not make a fullscreen window's top edge
    /// behave like a visible menu bar. Check the actual hit-test ancestry.
    private func isMenuBarHit(at point: CGPoint) -> Bool {
        var element = AXHelpers.element(at: point)
        for _ in 0..<8 {
            guard let current = element else { return false }
            let role: String? = try? current.attribute(.role)
            if role == kAXMenuBarRole || role == kAXMenuBarItemRole { return true }
            if let pid = AXHelpers.pid(for: current),
               NSRunningApplication(processIdentifier: pid)?.bundleIdentifier == "com.apple.MenuBarAgent" {
                return true
            }
            element = try? current.attribute(.parent)
        }
        return false
    }
}
