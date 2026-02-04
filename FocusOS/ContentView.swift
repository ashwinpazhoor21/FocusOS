import SwiftUI

struct ContentView: View {
    @StateObject private var tracker = TrackingManager()
    @State private var dailySummaryText: String = ""

    var body: some View {
        VStack(spacing: 14) {
            Text("FocusOS")
                .font(.title2)
                .bold()

            Text(tracker.isTracking ? "Tracking is ON" : "Tracking is OFF")
                .foregroundStyle(tracker.isTracking ? .green : .secondary)

            HStack(spacing: 12) {
                Button("Start Tracking") {
                    tracker.startTracking(interval: 2.0)
                }
                .disabled(tracker.isTracking)

                Button("Stop Tracking") {
                    tracker.stopTracking()
                }
                .disabled(!tracker.isTracking)
            }

            Divider().padding(.vertical, 6)


            VStack(spacing: 8) {
                Button(tracker.isFocusModeEnabled ? "Disable Focus Mode" : "Enable Focus Mode") {
                    tracker.toggleFocusMode()
                }

                if tracker.isFocusModeEnabled {
                    Text("Focus Mode is ON")
                        .foregroundStyle(.green)
                        .font(.callout)
                } else {
                    Text("Focus Mode is OFF")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }

                if !tracker.lastViolationText.isEmpty {
                    Text(tracker.lastViolationText)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }

            Divider().padding(.vertical, 6)

            Button("Generate Daily Summary") {
                Sessionizer.rebuildSessions(forDay: Date())
                let m = MetricsEngine.metrics(forDay: Date())
                dailySummaryText = DailySummaryGenerator.makeSummary(for: Date(), metrics: m)
            }

            if !dailySummaryText.isEmpty {
                ScrollView {
                    Text(dailySummaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
                .frame(height: 200)
            } else {
                Text("No summary yet. Click “Generate Daily Summary”.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(width: 340)
    }
}

#Preview {
    ContentView()
}
