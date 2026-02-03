import SwiftUI

struct ContentView: View {
    @StateObject private var tracker = TrackingManager()

    // ✅ Holds the summary text shown inside the app
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

            // ✅ Generates sessions + metrics + summary and shows it in the popover
            Button("Generate Daily Summary") {
                Sessionizer.rebuildSessions(forDay: Date())
                let m = MetricsEngine.metrics(forDay: Date())
                dailySummaryText = DailySummaryGenerator.makeSummary(for: Date(), metrics: m)
            }

            // ✅ Summary shown inside the menu bar popover (not Xcode console)
            if !dailySummaryText.isEmpty {
                ScrollView {
                    Text(dailySummaryText)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
                .frame(height: 200)
                .padding(.top, 4)
            } else {
                Text("No summary yet. Click “Generate Daily Summary”.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(width: 320) // slightly wider so summary looks good
    }
}

#Preview {
    ContentView()
}
