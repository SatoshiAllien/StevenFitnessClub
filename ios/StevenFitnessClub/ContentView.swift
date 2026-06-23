import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthKit: HealthKitService
    @EnvironmentObject var dataStore: WorkoutDataStore
    @State private var selectedTab = 0
    @State private var showAuthAlert = false
    @State private var showSyncAlert = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
                .tag(0)

            ActivitiesListView()
                .tabItem { Label("Attività", systemImage: "figure.run") }
                .tag(1)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "sparkles") }
                .tag(2)

            CompareView()
                .tabItem { Label("Confronti", systemImage: "arrow.left.arrow.right") }
                .tag(3)

            ExportView()
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
                .tag(4)
        }
        .tint(SFC.Color.electricBlue)
        .onChange(of: healthKit.authorizationError) { _, error in
            showAuthAlert = error != nil
        }
        .onChange(of: dataStore.syncError) { _, error in
            showSyncAlert = error != nil
        }
        .alert("Apple Salute", isPresented: $showAuthAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(healthKit.authorizationError ?? "")
        }
        .alert("Errore sincronizzazione", isPresented: $showSyncAlert) {
            Button("OK", role: .cancel) { dataStore.syncError = nil }
        } message: {
            Text(dataStore.syncError ?? "")
        }
    }
}