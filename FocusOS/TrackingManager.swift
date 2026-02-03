//
//  TrackingManager.swift
//  FocusOS
//
//  Created by Ashwin Pazhoor on 2/2/26.
//

import Foundation
import AppKit

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

    private func logFrontmostApp() {
        let now = ISO8601DateFormatter().string(from: Date())

        if let app = NSWorkspace.shared.frontmostApplication {
            let name = app.localizedName ?? "Unknown"
            let bundleID = app.bundleIdentifier ?? "NoBundleID"
            print("\(now) | \(bundleID) | \(name)")
        } else {
            print("\(now) | No frontmost application")
        }
    }
}
