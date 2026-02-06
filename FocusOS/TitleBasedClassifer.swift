//
//  TitleBasedClassifer.swift
//  FocusOS
//
//  Created by Ashwin Pazhoor on 2/3/26.
//

import Foundation

final class TitleBasedClassifier {

    static let browserBundleIDs: Set<String> = [
        "com.google.Chrome",
        "com.apple.Safari",
        "company.thebrowser.Browser"
    ]

    static let distractionKeywords: [String] = [
        "youtube", "netflix", "hulu", "prime video",
        "reddit", "twitter", "x.com", "instagram", "tiktok",
        "twitch", "discord", "spotify", "music"
    ]

    static let productiveKeywords: [String] = [
        "canvas", "gradescope", "piazza",
        "github", "pull request", "issue",
        "stack overflow", "documentation", "docs",
        "leetcode", "hackerrank",
        "pdf", "lecture", "notes", "syllabus",
        "google docs", "notion"
    ]

    static func classify(bundleId: String, windowTitle: String?) -> AppCategory {
        guard browserBundleIDs.contains(bundleId) else {
            return AppCategorizer.category(for: bundleId)
        }

        guard let t = windowTitle?.lowercased(), !t.isEmpty else {
            return .shallowWork
        }

        if distractionKeywords.contains(where: { t.contains($0) }) {
            return .distraction
        }

        if productiveKeywords.contains(where: { t.contains($0) }) {
            return .shallowWork
        }

        return .shallowWork
    }
}
