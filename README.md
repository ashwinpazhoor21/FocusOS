# FocusOS

FocusOS is a macOS menu bar productivity app that tracks application usage, analyzes focus patterns, and delivers real-time and end-of-day feedback to help users stay focused. It is designed as a personal productivity agent that integrates deeply with macOS system features such as notifications, the menu bar, and local system APIs.

This project is built entirely in Swift using AppKit and stores all data locally using SQLite.

---

## Features

### Application Usage Tracking
- Continuously tracks the frontmost application while the user is active
- Detects idle time using system input events
- Logs activity events locally for privacy and reliability

### Focus Sessions and Metrics
- Reconstructs focus sessions from raw app events
- Computes daily metrics including:
  - Total active time
  - Longest uninterrupted focus session
  - Context switches between applications
  - Top applications by usage time
  - Deep work, shallow work, and distraction time

### Focus Mode
- Allows users to enable a Focus Mode to reduce distractions
- Detects when distracting applications are opened during Focus Mode
- Triggers system notifications with sound feedback on violations
- Logs violations for later analysis

### Daily Summary Notifications
- Automatically sends a natural language summary notification at the end of the day
- Summarizes productivity, focus patterns, and distraction behavior
- Designed to provide actionable feedback rather than raw statistics

### Privacy First
- All data is stored locally using SQLite
- No cloud services or external analytics
- No personal data leaves the device

---

## Architecture Overview

FocusOS is built with a modular architecture focused on clarity and extensibility.

- **AppKit + SwiftUI**
  - AppKit for menu bar and system-level integration
  - SwiftUI for lightweight UI inside the menu bar popover

- **TrackingManager**
  - Handles app tracking, idle detection, Focus Mode logic, and notifications

- **SQLiteManager**
  - Manages database lifecycle, migrations, and queries
  - Stores app events, focus sessions, and Focus Mode violations

- **Sessionizer**
  - Converts raw app events into meaningful focus sessions

- **MetricsEngine**
  - Aggregates daily metrics from session data
  - Categorizes time into deep work, shallow work, and distractions

- **DailySummaryGenerator**
  - Converts metrics into natural language summaries

- **NotificationManager**
  - Handles immediate and scheduled macOS notifications

---

## Technologies Used

- Swift
- AppKit
- SwiftUI
- SQLite
- UserNotifications
- CoreGraphics
- macOS Accessibility and system APIs

---

## Current Status

FocusOS is under active development. Recent updates include:
- End-of-day automated summary notifications
- Focus Mode violation tracking and alerts
- Expanded productivity metrics and categorization

Planned next steps include:
- Exploring system-level window and application control for stricter Focus Mode enforcement
- More advanced productivity insights based on historical trends
- Weekly summary reports

---

## Motivation

FocusOS was built as a personal tool to better understand and improve my own productivity while also serving as a learning project to explore macOS system programming, AppKit, and local data pipelines. The goal is to build something practical, performant, and deeply integrated with the operating system rather than a generic cross platform app.
