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
    private var rehideTask: Task<Void, Never>?
    private var dragging = false
    private lazy var scrollMonitor = EventMonitor.passive(for: .scrollWheel, scope: .universal) { [weak self] event in
        self?.handleScroll(event)
    }
    private lazy var mouseMonitor = EventMonitor.passive(
        for: [.leftMouseDown, .leftMouseUp, .leftMouseDragged, .rightMouseDown], scope: .universal
    ) { [weak self] event in
        self?.handleMouse(event)
    }

    func performSetup(with appState: AppState) {
        self.appState = appState
        start()
    }

    func start() {
        enabled = enabledStack.popLast() ?? true
        if enabled {
            scrollMonitor.start()
            mouseMonitor.start()
        }
    }

    func stop() {
        enabledStack.append(enabled)
        enabled = false
        scrollMonitor.stop()
        mouseMonitor.stop()
        rehideTask?.cancel()
        rehideTask = nil
        dragging = false
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
            MouseHelpers.isButtonPressed() || event.modifierFlags.contains(.command) || isMenuTracking()
        guard let action = MacOS27InteractionRules.scrollAction(
            deltaX: event.scrollingDeltaX, deltaY: event.scrollingDeltaY, point: point,
            display: CGDisplayBounds(screen.displayID), control: ice.bounds, suppressed: suppressed
        ) else { return }
        rehideTask?.cancel()
        rehideTask = nil
        switch action {
        case .show: hidden.show(origin: .scroll, screen: screen)
        case .hide: hidden.hide(origin: .scroll, screen: screen)
        }
    }

    private func handleMouse(_ event: NSEvent) {
        guard #available(macOS 27.0, *), enabled else { return }
        if event.type == .leftMouseUp {
            dragging = false
            return
        }
        rehideTask?.cancel()
        rehideTask = nil
        dragging = event.type == .leftMouseDragged
        guard event.type == .leftMouseDown, let appState,
              appState.settings.general.autoRehide,
              appState.settings.general.rehideStrategy == .smart,
              let point = event.cgEvent?.location,
              !isMenuBarHit(at: point),
              let element = AXHelpers.element(at: point),
              !isMenuOrTransientElement(element),
              let pid = AXHelpers.pid(for: element),
              let owner = NSRunningApplication(processIdentifier: pid),
              owner != .current,
              owner.bundleIdentifier == "com.apple.dock" || owner.activationPolicy == .regular else { return }

        let revision = appState.menuBarManager.nativeVisibilityRevision
        rehideTask = Task { [weak self, weak appState] in
            do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
            guard let self, let appState, !Task.isCancelled else { return }
            var context = MacOS27InteractionRules.SmartRehideContext()
            context.enabled = enabled && appState.settings.general.autoRehide &&
                appState.settings.general.rehideStrategy == .smart
            context.hasVisibleSection = appState.menuBarManager.hasVisibleSection
            context.insideMenuBar = isMenuBarHit(at: point)
            context.settingsPresented = appState.navigationState.isSettingsPresented
            context.layoutEditing = appState.menuBarManager.macOS27Controller.isLayoutEditing
            context.dragging = dragging || MouseHelpers.isButtonPressed() ||
                NSEvent.modifierFlags.contains(.command) || appState.menuBarManager.isNativeDragInProgress
            context.menuTracking = isMenuOrTransientElement(AXHelpers.element(at: point)) || isMenuTracking()
            context.isIce = owner == .current
            context.isDock = owner.bundleIdentifier == "com.apple.dock"
            context.isRegularApplication = owner.activationPolicy == .regular
            context.isActiveApplication = owner.isActive && !owner.isTerminated
            context.requestIsCurrent = revision == appState.menuBarManager.nativeVisibilityRevision
            guard MacOS27InteractionRules.shouldSmartRehide(context) else { return }
            appState.menuBarManager.section(withName: .hidden)?.hide(origin: .automatic)
        }
    }

    private func isMenuTracking() -> Bool {
        let focused: UIElement? = try? systemWideElement.attribute(.focusedUIElement)
        return isMenuOrTransientElement(focused)
    }

    private func isMenuOrTransientElement(_ element: UIElement?) -> Bool {
        var element = element
        for _ in 0..<12 {
            guard let current = element else { return false }
            let role: String? = try? current.attribute(.role)
            if role == kAXMenuRole || role == kAXMenuItemRole || role == kAXMenuBarItemRole { return true }
            let subrole: String? = try? current.attribute(.subrole)
            if subrole == kAXFloatingWindowSubrole || subrole == kAXSystemDialogSubrole { return true }
            element = try? current.attribute(.parent)
        }
        return false
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
