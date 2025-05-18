import SwiftUI
import Charts

struct PerformanceChartView: View {
    let logEntries: [PoseLogEntry]
    let poses: [Pose]

    @State private var selectedPoseId: UUID? = nil
    @State private var selectedDate: Date?
    @State private var showWeekOnly = true
    @State private var chartType: ChartType = .repsAndXP

    enum ChartType: String, CaseIterable, Identifiable {
        case repsAndXP = "Reps & XP"
        case accuracyTrend = "Accuracy Trend"
        case consistencyTrend = "Consistency Trend"
        case routineFrequency = "Routine Frequency"
        case xpProgress = "XP Progress"

        var id: String { self.rawValue }
    }

    var body: some View {
        let filteredEntries = logEntries.filter { entry in
            selectedPoseId == nil || entry.poseId == selectedPoseId
        }

        let dailyStats = aggregateStatsPerDay(from: filteredEntries)
        let filteredStats = showWeekOnly ? filterToCurrentWeek(dailyStats) : dailyStats
        let maxReps = filteredStats.map(\.totalReps).max() ?? 10
        let maxXP = filteredStats.map(\.xpEarned).max() ?? 10
        let maxAccuracy = filteredStats.map(\.averageAccuracy).max() ?? 1.0
        let maxY = max(maxReps, maxXP)

        let totalWeekReps = filteredStats.map(\.totalReps).reduce(0, +)
        let currentStreak = computeStreak(from: filteredStats)

        VStack(alignment: .leading) {
            Text("📊 Performance Breakdown")
                .font(.title2)
                .bold()
                .padding(.top)

            Picker("Chart Type", selection: $chartType) {
                ForEach(ChartType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Picker("Pose", selection: $selectedPoseId) {
                Text("All Poses").tag(UUID?.none)
                ForEach(poses, id: \.id) { pose in
                    Text(pose.name).tag(Optional(pose.id))
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)

            HStack {
                Toggle("This Week Only", isOn: $showWeekOnly)
                    .toggleStyle(SwitchToggleStyle())
                Spacer()
                VStack(alignment: .trailing) {
                    Text("🔥 Weekly Reps: \(totalWeekReps)")
                        .font(.subheadline)
                    Text("📅 Streak: \(currentStreak) days")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)

            ZStack {
                switch chartType {
                case .repsAndXP:
                    Chart {
                        ForEach(filteredStats) { stat in
                            BarMark(
                                x: .value("Date", stat.date, unit: .day),
                                y: .value("Reps", stat.totalReps)
                            )
                            .foregroundStyle(stat.totalReps >= 15 ? .green : stat.totalReps >= 5 ? .yellow : .red)
                            .annotation(position: .top) {
                                if selectedDate == stat.date {
                                    Text("\(stat.totalReps) reps")
                                        .font(.caption2)
                                        .padding(4)
                                        .background(Color.black.opacity(0.75))
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                            }

                            BarMark(
                                x: .value("Date", stat.date, unit: .day),
                                y: .value("XP", stat.xpEarned)
                            )
                            .foregroundStyle(.blue)
                            .opacity(0.4)
                        }
                    }

                case .accuracyTrend:
                    Chart {
                        ForEach(filteredStats) { stat in
                            LineMark(
                                x: .value("Date", stat.date, unit: .day),
                                y: .value("Accuracy", stat.averageAccuracy * 100)
                            )
                            .foregroundStyle(.purple)
                            .interpolationMethod(.catmullRom)
                            .symbol(Circle())
                        }
                    }

                case .consistencyTrend:
                    Chart {
                        ForEach(filteredStats) { stat in
                            LineMark(
                                x: .value("Date", stat.date, unit: .day),
                                y: .value("Consistency", stat.consistency * 100)
                            )
                            .foregroundStyle(.orange)
                            .interpolationMethod(.catmullRom)
                            .symbol(Circle())
                        }
                    }

                case .routineFrequency:
                    let routineCounts = Dictionary(grouping: logEntries) { entry in
                        poses.first(where: { $0.id == entry.poseId })?.name ?? "Unknown"
                    }.mapValues { $0.count }

                    Chart {
                        ForEach(routineCounts.sorted(by: { $0.value > $1.value }), id: \.key) { name, count in
                            BarMark(
                                x: .value("Routine", name),
                                y: .value("Count", count)
                            )
                        }
                    }

                case .xpProgress:
                    Chart {
                        ForEach(filteredStats) { stat in
                            LineMark(
                                x: .value("Date", stat.date, unit: .day),
                                y: .value("XP", stat.xpEarned)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 7))
            }
            .chartYScale(domain: 0...max(maxY, Int(maxAccuracy * 100)))
            .padding(.bottom)

            Spacer()
        }
        .padding()
    }

    // MARK: - Data Aggregation

    func aggregateStatsPerDay(from entries: [PoseLogEntry]) -> [DailyStat] {
        let grouped = Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.timestamp)
        }

        return grouped.map { (date, entries) in
            let totalReps = entries.map(\.repsCompleted).reduce(0, +)
            let xpEarned = entries.map { entry in
                let pose = poses.first(where: { $0.id == entry.poseId })
                let reward = pose?.xpReward ?? 10
                return Int(Double(entry.accuracyScore) / 100.0 * Double(reward))
            }.reduce(0, +)

            let averageAccuracy = entries.isEmpty ? 0.0 :
                Double(entries.map(\.accuracyScore).reduce(0, +)) / Double(entries.count)
            let highAccuracies = entries.filter { Double($0.accuracyScore) / 100.0 > 0.8 }.count
            let consistency = entries.isEmpty ? 0.0 : Double(highAccuracies) / Double(entries.count)

            return DailyStat(
                date: date,
                totalReps: totalReps,
                xpEarned: xpEarned,
                averageAccuracy: averageAccuracy,
                consistency: consistency
            )
        }
        .sorted { $0.date < $1.date }
    }

    func filterToCurrentWeek(_ data: [DailyStat]) -> [DailyStat] {
        guard let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start else {
            return data
        }
        return data.filter { $0.date >= startOfWeek }
    }

    func computeStreak(from data: [DailyStat]) -> Int {
        let sorted = data.sorted { $0.date > $1.date }
        var streak = 0
        var expectedDate = Calendar.current.startOfDay(for: Date())

        for entry in sorted {
            if entry.date == expectedDate {
                streak += 1
                expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate)!
            } else {
                break
            }
        }
        return streak
    }

    struct DailyStat: Identifiable {
        let id = UUID()
        let date: Date
        let totalReps: Int
        let xpEarned: Int
        let averageAccuracy: Double
        let consistency: Double
    }
}
