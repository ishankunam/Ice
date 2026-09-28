//
//  MacOS27NativeMenuBarHiding.swift
//  Ice
//

import Cocoa
import OSLog

/// Hides a contiguous section by resizing an Ice-owned blank status item.
/// macOS lays out and handles every other item, including overflow and clicks.
@MainActor
final class MacOS27NativeMenuBarHiding {
    private struct Spacer {
        let item: NSStatusItem
    }

    private let logger = Logger(category: "MacOS27NativeMenuBarHiding")

    private var spacers = [MenuBarSection.Name: Spacer]()

    isolated deinit {
        removeAll()
    }

    /// A short description of a section's spacer, for logging.
    func debugDescription(for section: MenuBarSection.Name) -> String {
        guard let spacer = spacers[section] else { return "no spacer" }
        return "spacer visible=\(spacer.item.isVisible) length=\(spacer.item.length)"
    }

    func isConcealing(_ section: MenuBarSection.Name) -> Bool {
        guard let spacer = spacers[section] else { return false }
        return spacer.item.isVisible && spacer.item.length > 1
    }

    func prepare(section: MenuBarSection.Name, anchorPosition: CGFloat) {
        guard spacers[section] == nil else { return }
        let name = "Ice.NativeBoundary.\(section.rawValue).v2"
        // Equal preferred positions have unstable ordering after a relaunch.
        // The spacer must sort strictly to the left of the visible Ice item.
        let key = "NSStatusItem Preferred Position \(name)"
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(anchorPosition + 1, forKey: key)
        }
        let item = NSStatusBar.system.statusItem(withLength: 1)
        item.autosaveName = name
        item.button?.title = ""
        item.button?.image = nil
        item.button?.isEnabled = false
        item.button?.setAccessibilityIdentifier(name)
        spacers[section] = Spacer(item: item)
        withdraw(item)
    }

    /// AppKit reserves a real slot even for a one-point item. Publish the
    /// narrow boundary only while an explicit operation needs a drag handle.
    func prepareForHiding(anchorPosition: CGFloat) {
        prepare(section: .hidden, anchorPosition: anchorPosition)
        if let spacer = spacers[.hidden] { showNarrow(spacer.item) }
    }

    func showForLayout(anchorPosition: CGFloat, alwaysHiddenAnchor: CGFloat?) {
        prepare(section: .hidden, anchorPosition: anchorPosition)
        if let alwaysHiddenAnchor {
            prepare(section: .alwaysHidden, anchorPosition: alwaysHiddenAnchor)
        }
        for (section, spacer) in spacers {
            if section == .hidden || alwaysHiddenAnchor != nil {
                showNarrow(spacer.item)
            } else {
                withdraw(spacer.item)
            }
        }
    }

    private func showNarrow(_ item: NSStatusItem) {
        if item.length != 1 { item.length = 1 }
        if item.button?.isEnabled == false { item.button?.isEnabled = true }
        if !item.isVisible { item.isVisible = true }
    }

    private func withdraw(_ item: NSStatusItem) {
        guard item.isVisible else { return }
        logger.notice("Withdrawing \(item.autosaveName ?? "spacer", privacy: .public) (length \(item.length))")
        // Hiding an NSStatusItem clears its saved position. Preserve only our
        // own position; the pre-hide check reconciles native user reordering.
        let key = "NSStatusItem Preferred Position \(item.autosaveName ?? "")"
        let position = UserDefaults.standard.object(forKey: key)
        item.isVisible = false
        if let position { UserDefaults.standard.set(position, forKey: key) }
        if item.button?.isEnabled == true { item.button?.isEnabled = false }
    }

    /// Sets whether a section's spacer conceals the items to its left.
    ///
    /// - Parameter controlFrame: The current frame of the item immediately to
    ///   the right of the spacer, in global display coordinates. When known,
    ///   the spacer is sized to the space actually available to its left.
    @available(macOS 27.0, *)
    @discardableResult
    func setHidden(
        _ hidden: Bool,
        section: MenuBarSection.Name,
        anchorPosition: CGFloat,
        screen: NSScreen,
        controlFrame: CGRect? = nil
    ) -> Bool {
        guard hidden else {
            guard let spacer = spacers[section] else { return true }
            withdraw(spacer.item)
            return true
        }

        prepare(section: section, anchorPosition: anchorPosition)
        guard let spacer = spacers[section] else { return false }

        let length: CGFloat
        if let controlFrame {
            let notch: ClosedRange<CGFloat>?
            if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea,
               left.maxX <= right.minX {
                notch = left.maxX...right.minX
            } else {
                notch = nil
            }
            guard let measured = MacOS27MenuBarGeometry.concealingLength(
                control: controlFrame,
                display: CGDisplayBounds(screen.displayID),
                applicationMenu: applicationMenuFrame(on: screen),
                notch: notch
            ) else {
                withdraw(spacer.item)
                logger.notice("Keeping items visible because spacer geometry is unavailable or does not fit")
                return false
            }
            length = measured
        } else if spacer.item.isVisible, spacer.item.length > 1 {
            length = spacer.item.length
        } else {
            // Never guess a new spacer width without a frame on this display.
            withdraw(spacer.item)
            return false
        }

        if spacer.item.button?.isEnabled == true { spacer.item.button?.isEnabled = false }
        if spacer.item.length != length {
            logger.notice("Sizing \(section.rawValue, privacy: .public) spacer to \(length) (control frame: \(controlFrame?.debugDescription ?? "unknown", privacy: .public))")
            spacer.item.length = length
        }
        if !spacer.item.isVisible { spacer.item.isVisible = true }
        return true
    }

    /// AppKit's application-menu AX tree can retain the main screen's origin.
    /// Unnotched displays share that app menu layout, so translate its measured
    /// frame rather than rejecting a valid portrait or negative-origin display.
    private func applicationMenuFrame(on screen: NSScreen) -> CGRect? {
        guard let frame = screen.getApplicationMenuFrame() else { return nil }
        let target = CGDisplayBounds(screen.displayID)
        if MacOS27MenuBarGeometry.isOnMenuBar(frame, display: target) { return frame }
        guard !screen.hasNotch,
              let source = NSScreen.screens.first(where: {
                  MacOS27MenuBarGeometry.isOnMenuBar(frame, display: CGDisplayBounds($0.displayID))
              }), !source.hasNotch else { return nil }
        return MacOS27MenuBarGeometry.translatedApplicationMenu(
            frame, from: CGDisplayBounds(source.displayID), to: target
        )
    }

    /// The current length of a section's spacer, if it has one.
    func spacerLength(for section: MenuBarSection.Name) -> CGFloat? {
        spacers[section]?.item.length
    }

    /// Sets a section's spacer to an explicit length.
    ///
    /// The photo pass uses this to give back the menu bar space a few items at
    /// a time, so macOS draws them long enough to be photographed.
    @available(macOS 27.0, *)
    func setConcealingLength(_ length: CGFloat, section: MenuBarSection.Name, anchorPosition: CGFloat) {
        prepare(section: section, anchorPosition: anchorPosition)
        guard let spacer = spacers[section] else { return }
        let clamped = max(1, length)
        if spacer.item.length != clamped {
            spacer.item.length = clamped
        }
        if !spacer.item.isVisible {
            spacer.item.isVisible = true
        }
    }

    func removeAll() {
        for spacer in spacers.values {
            spacer.item.isVisible = false
            NSStatusBar.system.removeStatusItem(spacer.item)
        }
        spacers.removeAll()
    }
}
