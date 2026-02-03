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
                // quick way to verify it works without timer
                tracker.startTracking(interval: 999999) // hacky: starts then logs once
                tracker.stopTracking()
            }
            .font(.callout)
            .foregroundStyle(.secondary)

        }
        .padding(18)
        .frame(width: 280)
    }
}
#Preview {
    ContentView()
}
