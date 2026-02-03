import AppKit
import SwiftUI

final class StatusBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var eventMonitor: EventMonitor?

    init(rootView: ContentView) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        self.popover.contentSize = NSSize(width: 280, height: 220)
        self.popover.behavior = .transient
        self.popover.contentViewController = NSHostingController(rootView: rootView)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "FocusOS")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        self.eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self else { return }
            if self.popover.isShown {
                self.closePopover()
            }
        }
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            eventMonitor?.start()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        eventMonitor?.stop()
    }
}
