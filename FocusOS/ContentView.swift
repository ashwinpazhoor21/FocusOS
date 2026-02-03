import SwiftUI

struct ContentView: View {
    @StateObject private var tracker = TrackingManager()

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

            Button("Log Once (Debug)") {
                tracker.startTracking(interval: 999999)
                tracker.stopTracking()
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            
            Button("Build Sessions + Print Metrics") {
                Sessionizer.rebuildSessions(forDay: Date())
                let m = MetricsEngine.metrics(forDay: Date())

                print("📊 Daily Metrics")
                print("Total active min:", m.totalActiveMinutes)
                print("Context switches:", m.contextSwitches)
                print("Longest focus min:", m.longestFocusMinutes)
                print("Top apps:", m.topApps)
            }
            .font(.callout)
            .padding(.top, 6)

        }
        .padding(18)
        .frame(width: 280)
    }
}

#Preview {
    ContentView()
}
