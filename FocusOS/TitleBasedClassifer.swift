//
//  TitleBasedClassifer.swift
//  FocusOS
//
//  Created by Ashwin Pazhoor on 2/3/26.
//

import Foundation

final class TitleBasedClassifier {

    // Browsers we want to re-classify using titles
    static let browserBundleIDs: Set<String> = [
        "com.google.Chrome",
        "com.apple.Safari",
        "company.thebrowser.Browser"
    ]

    // If a title contains these → treat as distraction
    static let distractionKeywords: [String] = [
        "youtube", "netflix", "hulu", "prime video",
        "reddit", "twitter", "x.com", "instagram", "tiktok",
        "twitch", "discord", "spotify", "music"
    ]

    // If a title contains these → treat as productive study/research
    static let productiveKeywords: [String] = [
        "canvas", "gradescope", "piazza",
        "github", "pull request", "issue",
        "stack overflow", "documentation", "docs",
        "leetcode", "hackerrank",
        "pdf", "lecture", "notes", "syllabus",
        "google docs", "notion"
    ]

    static func classify(bundleId: String, windowTitle: String?) -> AppCategory {
        // Non-browser apps: default to your AppCategorizer
        guard browserBundleIDs.contains(bundleId) else {
            return AppCategorizer.category(for: bundleId)
        }

        // If no title, default browser category (shallow work)
        guard let t = windowTitle?.lowercased(), !t.isEmpty else {
            return .shallowWork
        }

        if distractionKeywords.contains(where: { t.contains($0) }) {
            return .distraction
        }

        if productiveKeywords.contains(where: { t.contains($0) }) {
            return .shallowWork
        }

        // Default: shallow work for browser
        return .shallowWork
    }
}
