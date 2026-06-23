import SwiftUI

struct ExportView: View {
    @EnvironmentObject var dataStore: WorkoutDataStore
    @EnvironmentObject var analytics: AnalyticsEngine
    @EnvironmentObject var insights: InsightsEngine
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var exportURL: URL?
    @State private var showShare = false
    @State private var statusMessage = ""

    private let exporter = ExportService()

    var body: some View {
        NavigationStack {
            VStack(spacing: SFC.Spacing.lg) {
                VStack(spacing: SFC.Spacing.sm) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(SFC.Color.electricBlue)
                    Text("Esporta i tuoi dati")
                        .font(SFC.Font.title(20))
                    Text("\(dataStore.workouts.count) allenamenti disponibili")
                        .font(SFC.Font.caption())
                        .foregroundStyle(SFC.Color.textSecondary)
                }
                .padding(.top, SFC.Spacing.xl)

                VStack(spacing: SFC.Spacing.md) {
                    ForEach(ExportFormat.allCases) { format in
                        ExportFormatRow(
                            format: format,
                            isSelected: selectedFormat == format
                        ) { selectedFormat = format }
                    }
                }
                .padding(.horizontal, SFC.Spacing.md)

                VStack(alignment: .leading, spacing: SFC.Spacing.sm) {
                    Text("Contenuto export")
                        .font(SFC.Font.headline(14))
                        .foregroundStyle(SFC.Color.textSecondary)
                    Label("Tutti i workout e metriche", systemImage: "checkmark.circle.fill")
                    Label("Performance scores e trend", systemImage: "checkmark.circle.fill")
                    Label("AI Insights e suggerimenti", systemImage: "checkmark.circle.fill")
                    if selectedFormat == .pdf {
                        Label("Grafici e analisi formattati", systemImage: "checkmark.circle.fill")
                    }
                }
                .font(SFC.Font.body(13))
                .foregroundStyle(SFC.Color.textPrimary)
                .padding(SFC.Spacing.md)
                .sfcCard()
                .padding(.horizontal, SFC.Spacing.md)

                Spacer()

                Button("Esporta \(selectedFormat.label)") { performExport() }
                    .buttonStyle(SFCButtonStyle())
                    .padding(.horizontal, SFC.Spacing.md)
                    .disabled(dataStore.workouts.isEmpty)

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(SFC.Font.caption())
                        .foregroundStyle(SFC.Color.performanceGreen)
                }
            }
            .padding(.bottom, SFC.Spacing.lg)
            .background(SFC.Color.deepBlack.ignoresSafeArea())
            .navigationTitle("Export")
            .sheet(isPresented: $showShare) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func performExport() {
        let url: URL?
        switch selectedFormat {
        case .csv:
            url = exporter.exportCSV(workouts: dataStore.workouts)
        case .json:
            url = exporter.exportJSON(
                workouts: dataStore.workouts,
                metrics: analytics.performanceMetrics,
                insights: insights.insights
            )
        case .pdf:
            url = exporter.exportPDF(
                workouts: dataStore.workouts,
                metrics: analytics.performanceMetrics,
                insights: insights.insights
            )
        }

        if let url {
            exportURL = url
            showShare = true
            statusMessage = "Export \(selectedFormat.label) pronto!"
        } else {
            statusMessage = "Errore durante l'export"
        }
    }
}

struct ExportFormatRow: View {
    let format: ExportFormat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: format.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? SFC.Color.electricBlue : SFC.Color.textSecondary)
                    .frame(width: 32)
                VStack(alignment: .leading) {
                    Text(format.label).font(SFC.Font.headline())
                    Text(formatDescription).font(SFC.Font.caption()).foregroundStyle(SFC.Color.textSecondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(SFC.Color.electricBlue)
                }
            }
            .padding(SFC.Spacing.md)
            .background(isSelected ? SFC.Color.electricBlue.opacity(0.1) : SFC.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: SFC.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: SFC.Radius.md)
                    .stroke(isSelected ? SFC.Color.electricBlue : SFC.Color.cardBorder, lineWidth: 1)
            )
        }
    }

    private var formatDescription: String {
        switch format {
        case .csv: return "Dati tabellari per Excel/Numbers"
        case .json: return "Dati completi con insights"
        case .pdf: return "Report professionale con analisi"
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}