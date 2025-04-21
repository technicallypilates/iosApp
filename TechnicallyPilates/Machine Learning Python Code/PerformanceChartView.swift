import SwiftUI
import Charts

struct PerformanceChartView: View {
    let logEntries: [PoseLogEntry]

    var body: some View {
        let dailyReps = aggregateRepsPerDay(from: logEntries)
        let maxReps = dailyReps.map(\.totalReps).max() ?? 10

        VStack {
            Text("📊 Reps Completed by Day")
                .font(.title2)
                .bold()
                .padding(.top)

            Chart(dailyReps) { entry in
                BarMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Reps", entry.totalReps)
                )
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .chartYScale(domain: 0...maxReps)
            .padding()

            Spacer()
        }
    }

    func aggregateRepsPerDay(from entries: [PoseLogEntry]) -> [DailyRepCount] {
        let grouped = Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.timestamp)
        }

        return grouped.map { (date, entries) in
            DailyRepCount(date: date, totalReps: entries.map(\.repsCompleted).reduce(0, +))
        }.sorted { $0.date < $1.date }
    }

    struct DailyRepCount: Identifiable {
        let id = UUID()
        let date: Date
        let totalReps: Int
    }
}

