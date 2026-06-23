import SwiftUI

@main
struct StevenFitnessClubApp: App {
    @StateObject private var healthKit = HealthKitService()
    @StateObject private var dataStore = WorkoutDataStore()
    @StateObject private var analytics = AnalyticsEngine()
    @StateObject private var insights = InsightsEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKit)
                .environmentObject(dataStore)
                .environmentObject(analytics)
                .environmentObject(insights)
                .preferredColorScheme(.dark)
                .task {
                    await healthKit.requestAuthorization()
                    if healthKit.isAuthorized {
                        await dataStore.syncFromHealthKit(healthKit: healthKit)
                        analytics.compute(from: dataStore.workouts)
                        insights.generate(workouts: dataStore.workouts, metrics: analytics.performanceMetrics)
                    }
                }
        }
    }
}