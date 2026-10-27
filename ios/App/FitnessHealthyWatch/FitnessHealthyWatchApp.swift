import SwiftUI

@main
struct FitnessHealthyWatchApp: App {
    @StateObject private var bridge = WatchSessionBridge.shared
    @StateObject private var health = WatchWorkoutHealth.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bridge)
                .environmentObject(health)
                .onAppear {
                    bridge.activate()
                    health.requestAuth()
                }
        }
    }
}
