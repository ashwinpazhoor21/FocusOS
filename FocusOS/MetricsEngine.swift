//
//  MetricsEngine.swift
//  FocusOS
//
//  Created by Ashwin Pazhoor on 2/2/26.
//

import Foundation

struct DailyMetrics {
    let totalActiveMinutes: Int
    let contextSwitches: Int
    let longestFocusMinutes: Int
    let topApps: [(String, Int)]
}

final class MetricsEngine {
    static func metrics(forDay day: Date) -> DailyMetrics {
        let sessions = SQLiteManager.shared.fetchSessions(forDay: day)

        let totalMin = sessions.reduce(0) { $0 + ($1.durationSec / 60) }
        let longestMin = sessions.map { $0.durationSec / 60 }.max() ?? 0

        var switches = 0
        for i in 1..<sessions.count {
            if sessions[i].bundleId != sessions[i-1].bundleId {
                switches += 1
            }
        }

        var byApp: [String: Int] = [:]
        for s in sessions {
            byApp[s.appName, default: 0] += s.durationSec / 60
        }
        let top = byApp.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }

        return DailyMetrics(
            totalActiveMinutes: totalMin,
            contextSwitches: switches,
            longestFocusMinutes: longestMin,
            topApps: top
        )
    }
}
