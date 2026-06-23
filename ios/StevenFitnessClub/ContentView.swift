import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

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
    }
}