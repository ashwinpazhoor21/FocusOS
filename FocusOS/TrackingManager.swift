//
//  TrackingManager.swift
//  FocusOS
//
//  Created by Ashwin Pazhoor on 2/2/26.
//

import Foundation
import AppKit
import CoreGraphics

final class TrackingManager: ObservableObject {
    @Published var isTracking: Bool = false

    // Focus Mode state + last violation for UI
    @Published var isFocusModeEnabled: Bool = false
    @Published var lastViolationText: String = ""

    private var timer: Timer?

    // Cooldown to prevent notification spam
    private var lastNotifyAtByBundle: [String: Date] = [:]
    private let notifyCooldownSec: TimeInterval = 25

    func startTracking(interval: TimeInterval = 2.0) {
        guard !isTracking else { return }

        // ✅ Ask for notification permission once user opts into tracking
        NotificationManager.shared.requestAuthorization()

        isTracking = true

        logFrontmostApp()

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.logFrontmostApp()
        }

        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stopTracking() {
        timer?.invalidate()
        timer = nil
        isTracking = false
    }

    func toggleFocusMode() {
        isFocusModeEnabled.toggle()
        lastViolationText = ""
    }

    private func isIdle(thresholdSec: Double = 60) -> Bool {
        let mouseIdle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
        let keyIdle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        let idleTime = min(mouseIdle, keyIdle)
        return idleTime >= thresholdSec
    }

    private func isBlockedInFocusMode(bundleId: String) -> Bool {
        let blockedApps: Set<String> = [
            "com.apple.MobileSMS", // Messages
            "com.spotify.client",  // Spotify
            "com.hnc.Discord",     // Discord
            "com.apple.mail"       // Mail
            // Slack not blocked by default
        ]
        return isFocusModeEnabled && blockedApps.contains(bundleId)
    }

    private func shouldNotify(bundleId: String, now: Date) -> Bool {
        if let last = lastNotifyAtByBundle[bundleId] {
            return now.timeIntervalSince(last) >= notifyCooldownSec
        }
        return true
    }

    private func markNotified(bundleId: String, now: Date) {
        lastNotifyAtByBundle[bundleId] = now
    }

    private func logFrontmostApp() {
        let now = Date()
        let idle = isIdle(thresholdSec: 60)

        guard let app = NSWorkspace.shared.frontmostApplication else { return }

        let name = app.localizedName ?? "Unknown"
        let bundleID = app.bundleIdentifier ?? "NoBundleID"

        // Window title paused for now
        let title: String? = nil

        SQLiteManager.shared.insertAppEvent(
            timestamp: now,
            bundleId: bundleID,
            appName: name,
            isIdle: idle,
            windowTitle: title
        )

        // ✅ Focus Mode: notify + sound on violations (only when active and not idle)
        if !idle && isBlockedInFocusMode(bundleId: bundleID) {
            lastViolationText = "🚫 Focus Mode: \(name) is blocked"
            print("🚫 Focus Mode violation: \(bundleID) | \(name)")

            // ✅ Log violation to DB (so daily summary can include it later)
            SQLiteManager.shared.insertViolation(
                timestamp: now,
                bundleId: bundleID,
                appName: name
            )

            if shouldNotify(bundleId: bundleID, now: now) {
                NotificationManager.shared.notify(
                    title: "FocusOS: Focus Mode",
                    body: "\(name) is blocked during focus mode."
                )
                markNotified(bundleId: bundleID, now: now)
            }
        }

        print("Saved event: \(bundleID) | \(name) | idle=\(idle)")
    }
}
