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
    private var timer: Timer?

    func startTracking(interval: TimeInterval = 2.0) {
        guard !isTracking else { return }
        isTracking = true

    
        logFrontmostApp()

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.logFrontmostApp()
        }

        
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stopTracking() {
        timer?.invalidate()
        timer = nil
        isTracking = false
    }
    private func isIdle(thresholdSec: Double = 60) -> Bool {
        let mouseIdle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
        let keyIdle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        let idleTime = min(mouseIdle, keyIdle)
        return idleTime >= thresholdSec
    }

    private func logFrontmostApp() {
        let now = Date()
        let idle = isIdle(thresholdSec: 60)

        if let app = NSWorkspace.shared.frontmostApplication {
            let name = app.localizedName ?? "Unknown"
            let bundleID = app.bundleIdentifier ?? "NoBundleID"

            SQLiteManager.shared.insertAppEvent(
                timestamp: now,
                bundleId: bundleID,
                appName: name,
                isIdle: idle
            )

            print("Saved event: \(bundleID) | \(name) | idle=\(idle)")
        }
    }
}
