//
//  Sessionizer.swift
//  FocusOS
//
//  Created by Ashwin Pazhoor on 2/2/26.
//

import Foundation

final class Sessionizer {
    static func rebuildSessions(forDay day: Date) {
        let events = SQLiteManager.shared.fetchAppEvents(forDay: day)
        SQLiteManager.shared.deleteSessions(forDay: day)

        guard !events.isEmpty else { return }

        let maxGap: TimeInterval = 10 
        let minSession: TimeInterval = 10

        var currentStart = events[0].ts
        var lastTs = events[0].ts
        var currentBundle = events[0].bundleId
        var currentName = events[0].appName
        var endedByIdle = false

        func closeSession(_ end: Date, endedByIdle: Bool) {
            let dur = end.timeIntervalSince(currentStart)
            guard dur >= minSession else { return }

            SQLiteManager.shared.insertSession(
                start: currentStart,
                end: end,
                bundleId: currentBundle,
                appName: currentName,
                durationSec: Int(dur),
                endedByIdle: endedByIdle
            )
        }

        for i in 1..<events.count {
            let e = events[i]
            let gap = e.ts.timeIntervalSince(lastTs)

            let shouldBreak =
                e.bundleId != currentBundle ||
                e.isIdle == true ||
                gap > maxGap

            if shouldBreak {
                closeSession(lastTs, endedByIdle: (e.isIdle || gap > maxGap))

                
                currentStart = e.ts
                currentBundle = e.bundleId
                currentName = e.appName
                endedByIdle = e.isIdle
            }

            lastTs = e.ts
        }

        closeSession(lastTs, endedByIdle: endedByIdle)
    }
}
