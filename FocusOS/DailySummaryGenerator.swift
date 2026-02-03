//
//  DailySummaryGenerator.swift
//  FocusOS
//
//  Created by Ashwin Pazhoor on 2/3/26.
//

import Foundation

final class DailySummaryGenerator {

    static func makeSummary(for day: Date, metrics m: DailyMetrics) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        let dateString = df.string(from: day)

        let topAppsText: String = {
            if m.topApps.isEmpty {
                return "No app usage recorded."
            }
            return m.topApps
                .map { "\($0.0) (\($0.1)m)" }
                .joined(separator: ", ")
        }()

        // Context switch rate per hour
        let switchRate: String = {
            guard m.totalActiveMinutes > 0 else { return "0/hr" }
            let hours = Double(m.totalActiveMinutes) / 60.0
            let rate = Double(m.contextSwitches) / max(hours, 0.1)
            return String(format: "%.1f/hr", rate)
        }()

        // Focus quality heuristic
        let focusQuality: String = {
            if m.longestFocusMinutes >= 40 {
                return "strong"
            } else if m.longestFocusMinutes >= 25 {
                return "decent"
            } else {
                return "fragmented"
            }
        }()

        // Recommendations
        var recs: [String] = []

        if m.contextSwitches >= 60 {
            recs.append("Your context switching was high. Try one 25-minute focus block with only one app open.")
        } else if m.contextSwitches >= 30 {
            recs.append("Try grouping similar tasks together to reduce app switching.")
        } else {
            recs.append("Nice job keeping context switching low. Try extending one focus block tomorrow.")
        }

        if m.longestFocusMinutes < 20 {
            recs.append("Your longest focus block was under 20 minutes. Aim for a 25-minute uninterrupted session.")
        } else if m.longestFocusMinutes < 40 {
            recs.append("Try pushing your best focus block to 40 minutes by pausing notifications.")
        } else {
            recs.append("Great focus endurance today. Protect that time window tomorrow.")
        }

        if m.totalActiveMinutes < 60 {
            recs.append("You had low active time today. Try scheduling one dedicated study block tomorrow.")
        }

        // Build final summary text
        var lines: [String] = []
        lines.append("Daily Summary (\(dateString))")
        lines.append("")
        lines.append("You were active for \(m.totalActiveMinutes) minutes.")
        lines.append("Longest focus block: \(m.longestFocusMinutes) minutes.")
        lines.append("Context switches: \(m.contextSwitches) (\(switchRate)). Focus quality: \(focusQuality).")
        lines.append("")
        lines.append("Top apps:")
        lines.append(topAppsText)
        lines.append("")
        lines.append("What to improve tomorrow:")
        for (i, r) in recs.prefix(3).enumerated() {
            lines.append("\(i + 1). \(r)")
        }

        return lines.joined(separator: "\n")
    }
}
