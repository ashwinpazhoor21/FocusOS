//
//  DailySummaryScheduler.swift
//  FocusOS
//
//  Created by Ashwin Pazhoor on 2/5/26.
//

import Foundation

final class DailySummaryScheduler {

    static func buildSummaryText(for day: Date) -> String {

        Sessionizer.rebuildSessions(forDay: day)
        let metrics = MetricsEngine.metrics(forDay: day)
        return DailySummaryGenerator.makeSummary(for: day, metrics: metrics)
    }

    static func scheduleDailyAt8PM() {
        let body = buildSummaryText(for: Date())
        NotificationManager.shared.scheduleDailySummaryAt8PM(body: body)
    }

    static func scheduleTestIn10Seconds() {
        let body = buildSummaryText(for: Date())
        NotificationManager.shared.scheduleTestSummaryIn(seconds: 10, body: body)
    }
}
