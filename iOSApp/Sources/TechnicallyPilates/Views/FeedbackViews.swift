import SwiftUI

// MARK: - Accuracy Feedback Components
struct AccuracyRing: View {
    let accuracy: Double
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: accuracy)
                .stroke(
                    LinearGradient(
                        colors: [.red, .yellow, .green],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(accuracy * 100))%")
                .font(.system(size: size * 0.3, weight: .bold))
        }
        .frame(width: size, height: size)
    }
}

struct AccuracyBar: View {
    let accuracy: Double
    let height: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: height)
                    .opacity(0.2)
                    .foregroundColor(.gray)
                
                Rectangle()
                    .frame(width: geometry.size.width * accuracy, height: height)
                    .foregroundColor(
                        LinearGradient(
                            colors: [.red, .yellow, .green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .cornerRadius(height / 2)
        }
    }
}

// MARK: - XP Feedback Components
struct XPPopup: View {
    let xp: Int
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        Text("+\(xp) XP")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(20)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    offset = -50
                    opacity = 0
                }
            }
    }
}

struct LevelProgressBar: View {
    let currentXP: Int
    let totalXP: Int
    let level: Int
    
    var progress: Double {
        Double(currentXP % 1000) / 1000.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Level \(level)")
                    .font(.headline)
                Spacer()
                Text("\(currentXP)/\(totalXP) XP")
                    .font(.subheadline)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 8)
                        .opacity(0.2)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: geometry.size.width * progress, height: 8)
                        .foregroundColor(.blue)
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Achievement Components
struct AchievementPopup: View {
    let achievement: Achievement
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        VStack(spacing: 16) {
            if let imageURL = achievement.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                } placeholder: {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 40))
                }
            }
            
            Text(achievement.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(achievement.description)
                .font(.subheadline)
                .multilineTextAlignment(.center)
            
            Text("+\(achievement.xpReward) XP")
                .font(.headline)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1
            }
        }
    }
}

// MARK: - Performance Summary
struct PerformanceSummary: View {
    let accuracy: Double
    let xpEarned: Int
    let bonuses: [String]
    let progressToNextLevel: Double
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Performance Summary")
                .font(.title2)
                .fontWeight(.bold)
            
            AccuracyRing(accuracy: accuracy, size: 100)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Accuracy: \(Int(accuracy * 100))%")
                    .font(.headline)
                
                Text("XP Earned: \(xpEarned)")
                    .font(.headline)
                
                if !bonuses.isEmpty {
                    Text("Bonuses:")
                        .font(.headline)
                    ForEach(bonuses, id: \.self) { bonus in
                        Text("• \(bonus)")
                            .font(.subheadline)
                    }
                }
                
                LevelProgressBar(
                    currentXP: Int(progressToNextLevel * 1000),
                    totalXP: 1000,
                    level: Int(progressToNextLevel) + 1
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

// MARK: - Statistics View
struct StatisticsView: View {
    let logEntries: [PoseLogEntry]
    
    var averageAccuracy: Double {
        guard !logEntries.isEmpty else { return 0 }
        return logEntries.reduce(0) { $0 + $1.accuracy } / Double(logEntries.count)
    }
    
    var totalXP: Int {
        logEntries.reduce(0) { $0 + $1.xpEarned }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Statistics")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                StatRow(title: "Average Accuracy", value: "\(Int(averageAccuracy * 100))%")
                StatRow(title: "Total XP Earned", value: "\(totalXP)")
                StatRow(title: "Total Poses", value: "\(logEntries.count)")
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 5)
        }
        .padding()
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Achievement Gallery
struct AchievementGallery: View {
    let achievements: [Achievement]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
            .padding()
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            if let imageURL = achievement.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                } placeholder: {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 30))
                }
            }
            
            Text(achievement.name)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.caption)
                .multilineTextAlignment(.center)
            
            if achievement.isUnlocked {
                Text("+\(achievement.xpReward) XP")
                    .font(.caption)
                    .foregroundColor(.blue)
            } else {
                Text("Locked")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .opacity(achievement.isUnlocked ? 1 : 0.5)
    }
}

// MARK: - Progress Calendar
struct ProgressCalendar: View {
    let logEntries: [PoseLogEntry]
    
    var entriesByDate: [Date: [PoseLogEntry]] {
        Dictionary(grouping: logEntries) { entry in
            Calendar.current.startOfDay(for: entry.timestamp)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Calendar.current.datesInMonth(), id: \.self) { date in
                    if let entries = entriesByDate[date] {
                        let totalXP = entries.reduce(0) { $0 + $1.xpEarned }
                        CalendarDayCell(date: date, xp: totalXP)
                    } else {
                        CalendarDayCell(date: date, xp: 0)
                    }
                }
            }
            .padding()
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let xp: Int
    
    var body: some View {
        VStack {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption)
            
            if xp > 0 {
                Text("\(xp) XP")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .frame(height: 50)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: xp > 0 ? 2 : 0)
    }
}

// Extension for Calendar dates
extension Calendar {
    func datesInMonth() -> [Date] {
        let today = Date()
        let range = self.range(of: .day, in: .month, for: today)!
        let firstDay = self.date(from: self.dateComponents([.year, .month], from: today))!
        
        return (0..<range.count).compactMap { day in
            self.date(byAdding: .day, value: day, to: firstDay)
        }
    }
} 