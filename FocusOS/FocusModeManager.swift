//
//  FocusModeManager.swift
//  FocusOS
//
//  Created by Ashwin Pazhoor on 2/3/26.
//

import Foundation

final class FocusModeManager: ObservableObject {
    @Published var isFocusModeEnabled: Bool = false


    let blockedApps: Set<String> = [
        "com.apple.MobileSMS",
        "com.spotify.client",
        "com.hnc.Discord",
        "com.tinyspeck.slackmacgap",
        "com.apple.mail"             
    ]

    func toggle() {
        isFocusModeEnabled.toggle()
    }

    func isBlocked(bundleId: String) -> Bool {
        isFocusModeEnabled && blockedApps.contains(bundleId)
    }
}
