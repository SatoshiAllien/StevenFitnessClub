import Foundation
import UIKit
import PDFKit

enum ExportFormat: String, CaseIterable, Identifiable {
    case csv, json, pdf
    var id: String { rawValue }
    var label: String { rawValue.uppercased() }
    var icon: String {
        switch self {
        case .csv: return "tablecells"
        case .json: return "curlybraces"
        case .pdf: return "doc.richtext"
        }
    }
}

struct ExportService {
    func exportCSV(workouts: [WorkoutActivity]) -> URL? {
        var csv = "date,sport,duration_sec,distance_km,pace_sec_per_km,calories,avg_hr,max_hr,avg_power,elevation_m\n"
        let formatter = ISO8601DateFormatter()
        for w in workouts {
            csv += [
                formatter.string(from: w.startDate),
                w.sport.rawValue,
                String(format: "%.0f", w.duration),
                String(format: "%.3f", w.distanceKm ?? 0),
                String(format: "%.1f", w.avgPaceSecPerKm ?? 0),
                String(format: "%.0f", w.activeCalories ?? 0),
                String(format: "%.0f", w.avgHeartRate ?? 0),
                String(format: "%.0f", w.maxHeartRate ?? 0),
                String(format: "%.0f", w.avgPower ?? 0),
                String(format: "%.0f", w.elevationGain ?? 0),
            ].joined(separator: ",") + "\n"
        }
        return writeTemp(csv, name: "steven_fitness_export.csv")
    }

    func exportJSON(workouts: [WorkoutActivity], metrics: PerformanceMetrics, insights: [AIInsight]) -> URL? {
        struct ExportBundle: Codable {
            let exportedAt: Date
            let workoutCount: Int
            let workouts: [WorkoutActivity]
            let performanceMetrics: PerformanceMetrics
            let insights: [AIInsight]
        }
        let bundle = ExportBundle(
            exportedAt: Date(), workoutCount: workouts.count,
            workouts: workouts, performanceMetrics: metrics, insights: insights
        )
        guard let data = try? JSONEncoder().encode(bundle) else { return nil }
        return writeTemp(data, name: "steven_fitness_export.json")
    }

    func exportPDF(
        workouts: [WorkoutActivity],
        metrics: PerformanceMetrics,
        insights: [AIInsight]
    ) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 40

            func draw(_ text: String, font: UIFont, color: UIColor = .white) {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let size = text.size(withAttributes: attrs)
                text.draw(at: CGPoint(x: 40, y: y), withAttributes: attrs)
                y += size.height + 8
            }

            UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1).setFill()
            ctx.fill(pageRect)

            draw("StevenFitnessClub", font: .boldSystemFont(ofSize: 28), color: UIColor(red: 0, green: 0.48, blue: 1, alpha: 1))
            draw("Report Analisi Fitness — \(Date().formatted(date: .long, time: .omitted))", font: .systemFont(ofSize: 14), color: .lightGray)
            y += 16

            draw("Performance Score: \(String(format: "%.0f", metrics.performanceScore))/100", font: .boldSystemFont(ofSize: 16))
            draw("Training Load: \(String(format: "%.1f", metrics.trainingLoad))", font: .systemFont(ofSize: 14))
            draw("VO₂ Max stimato: \(metrics.vo2MaxEstimate.map { String(format: "%.1f", $0) } ?? "N/D")", font: .systemFont(ofSize: 14))
            draw("Trend: \(metrics.trendDirection.label)", font: .systemFont(ofSize: 14))
            y += 16

            draw("Allenamenti (\(workouts.count))", font: .boldSystemFont(ofSize: 16), color: UIColor(red: 0, green: 1, blue: 0.5, alpha: 1))
            for w in workouts.prefix(15) {
                let line = "\(w.startDate.formatted(date: .abbreviated, time: .omitted)) — \(w.sport.displayName) — \(String(format: "%.1f", w.distanceKm ?? 0)) km"
                draw(line, font: .systemFont(ofSize: 11), color: .lightGray)
                if y > 700 { ctx.beginPage(); y = 40 }
            }
            y += 16

            draw("AI Insights", font: .boldSystemFont(ofSize: 16), color: UIColor(red: 1, green: 0.48, blue: 0, alpha: 1))
            for insight in insights.prefix(8) {
                draw("• \(insight.title)", font: .boldSystemFont(ofSize: 12))
                draw("  \(insight.body)", font: .systemFont(ofSize: 10), color: .lightGray)
                if y > 720 { ctx.beginPage(); y = 40 }
            }
        }

        return writeTemp(data, name: "steven_fitness_report.pdf")
    }

    private func writeTemp(_ string: String, name: String) -> URL? {
        writeTemp(Data(string.utf8), name: name)
    }

    private func writeTemp(_ data: Data, name: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url)
            return url
        } catch { return nil }
    }
}