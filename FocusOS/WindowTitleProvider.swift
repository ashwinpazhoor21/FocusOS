//
//  WindowTitleProvider.swift
//  FocusOS
//
//  Created by Ashwin Pazhoor on 2/3/26.
//

import Foundation
import AppKit
import ApplicationServices

final class WindowTitleProvider {

    /// Call this to trigger the system prompt (best effort) the first time user starts tracking.
    /// Returns whether the process is trusted *at the time of calling*.
    static func requestAccessibilityPermission() -> Bool {
        let options: CFDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Check if Accessibility permission is already enabled.
    static func isAccessibilityEnabled() -> Bool {
        AXIsProcessTrusted()
    }

    /// Opens System Settings to the Accessibility privacy panel.
    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    /// Returns the frontmost window title (if permitted). Uses multiple fallbacks (important for Arc).
    static func frontmostWindowTitle() -> String? {
        guard isAccessibilityEnabled() else { return nil }
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }

        let appElem = AXUIElementCreateApplication(app.processIdentifier)

        // 1) Focused window
        if let t = windowTitle(from: appElem, windowAttribute: kAXFocusedWindowAttribute as String) {
            return t
        }

        // 2) Main window (Arc often works better here)
        if let t = windowTitle(from: appElem, windowAttribute: kAXMainWindowAttribute as String) {
            return t
        }

        // 3) First window in windows list
        if let t = firstWindowTitle(from: appElem) {
            return t
        }

        return nil
    }

    // MARK: - Helpers

    private static func windowTitle(from appElem: AXUIElement, windowAttribute: String) -> String? {
        var windowValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElem, windowAttribute as CFString, &windowValue)
        guard result == .success, let windowValue = windowValue else { return nil }
        let windowElem = windowValue as! AXUIElement
        return titleFromWindow(windowElem)
    }

    private static func firstWindowTitle(from appElem: AXUIElement) -> String? {
        var windowsValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElem, kAXWindowsAttribute as CFString, &windowsValue)
        guard result == .success, let windowsValue = windowsValue else { return nil }
        let windows = windowsValue as! [AXUIElement]
        guard let first = windows.first else { return nil }
        return titleFromWindow(first)
    }

    private static func titleFromWindow(_ windowElem: AXUIElement) -> String? {
        var titleValue: AnyObject?
        let titleResult = AXUIElementCopyAttributeValue(windowElem, kAXTitleAttribute as CFString, &titleValue)
        guard titleResult == .success else { return nil }

        let title = (titleValue as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let t = title, !t.isEmpty else { return nil }
        return t
    }
}
