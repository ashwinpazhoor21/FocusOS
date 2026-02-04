//
//  FocusModeManager.swift
//  FocusOS
//
//  Created by Ashwin Pazhoor on 2/3/26.
//

import Foundation

final class FocusModeManager: ObservableObject {
    @Published var isFocusModeEnabled: Bool = false

    // Blocked apps during focus mode (bundle IDs)
    let blockedApps: Set<String> = [
        "com.apple.MobileSMS",       // Messages
        "com.spotify.client",        // Spotify
        "com.hnc.Discord",           // Discord
        "com.tinyspeck.slackmacgap", // Slack (move to allowed if you want)
        "com.apple.mail"             // Mail
    ]

    func toggle() {
        isFocusModeEnabled.toggle()
    }

    func isBlocked(bundleId: String) -> Bool {
        isFocusModeEnabled && blockedApps.contains(bundleId)
    }
}
