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

    let deepWorkMinutes: Int
    let shallowWorkMinutes: Int
    let distractionMinutes: Int
}

final class MetricsEngine {
    static func metrics(forDay day: Date) -> DailyMetrics {
        let sessions = SQLiteManager.shared.fetchSessions(forDay: day)

      
        let totalMin = sessions.reduce(0) { $0 + ($1.durationSec / 60) }
        let longestMin = sessions.map { $0.durationSec / 60 }.max() ?? 0

    
        var switches = 0
        if sessions.count >= 2 {
            for i in 1..<sessions.count {
                if sessions[i].bundleId != sessions[i - 1].bundleId {
                    switches += 1
                }
            }
        }

        var byApp: [String: Int] = [:]
        var deep = 0
        var shallow = 0
        var distract = 0

        for s in sessions {
            let mins = s.durationSec / 60

            byApp[s.appName, default: 0] += mins

            switch AppCategorizer.category(for: s.bundleId) {
            case .deepWork:
                deep += mins
            case .shallowWork:
                shallow += mins
            case .distraction:
                distract += mins
            case .unknown:
                break
            }
        }

        let top = byApp
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }

        return DailyMetrics(
            totalActiveMinutes: totalMin,
            contextSwitches: switches,
            longestFocusMinutes: longestMin,
            topApps: top,
            deepWorkMinutes: deep,
            shallowWorkMinutes: shallow,
            distractionMinutes: distract
        )
    }
}
