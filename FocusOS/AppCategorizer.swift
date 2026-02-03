import Foundation

enum AppCategory: String {
    case deepWork
    case shallowWork
    case distraction
    case unknown
}

final class AppCategorizer {

    // 🧠 Deep Work apps (coding / building)
    static let deepWork: Set<String> = [
        "com.apple.dt.Xcode",        // Xcode
        "com.microsoft.VSCode",      // VS Code
        "com.apple.Terminal",        // Terminal
        "com.googlecode.iterm2"      // iTerm2
    ]

    // 🟡 Shallow Work (research, communication, reading, admin)
    static let shallowWork: Set<String> = [
        "com.google.Chrome",             // Google Chrome
        "com.apple.Safari",              // Safari
        "company.thebrowser.Browser",    // Arc Browser
        "com.tinyspeck.slackmacgap",      // Slack
        "com.hnc.Discord",               // Discord
        "com.apple.mail"                 // Apple Mail
        // Gmail web is already under Chrome/Safari
    ]

    // 🔴 Distractions (non-work focus breakers)
    static let distraction: Set<String> = [
        "com.apple.MobileSMS",   // iMessage / Messages
        "com.spotify.client"     // Spotify
    ]

    static func category(for bundleId: String) -> AppCategory {
        if deepWork.contains(bundleId) { return .deepWork }
        if shallowWork.contains(bundleId) { return .shallowWork }
        if distraction.contains(bundleId) { return .distraction }
        return .unknown
    }
}
