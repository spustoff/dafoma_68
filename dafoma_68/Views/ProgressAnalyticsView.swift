//
//  ProgressAnalyticsView.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import SwiftUI

struct ProgressAnalyticsView: View {
    @EnvironmentObject var analyticsService: AnalyticsService
    @StateObject private var viewModel = ProgressAnalyticsViewModel(analyticsService: AnalyticsService(habitsService: HabitsService(), challengesService: ChallengesService()))
    @State private var showingAchievements = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#050505")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                        
                        // Overall progress
                        overallProgressView
                        
                        // Quick stats
                        quickStatsView
                        
                        // Time range selector
                        timeRangeSelectorView
                        
                        // Progress chart
                        progressChartView
                        
                        // Category breakdown
                        categoryBreakdownView
                        
                        // Recent achievements
                        recentAchievementsView
                        
                        // Insights
                        insightsView
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView(viewModel: viewModel)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Analytics")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Track your progress")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Productivity score
                VStack(spacing: 4) {
                    Text("\(viewModel.productivityScore)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "#F9FF14"))
                    
                    Text("Score")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: "#F9FF14").opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }
    
    private var overallProgressView: some View {
        VStack(spacing: 16) {
            Text("Overall Progress")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 12)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: viewModel.overallProgress)
                    .stroke(Color(hex: "#F9FF14"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: viewModel.overallProgress)
                
                VStack(spacing: 4) {
                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Complete")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var quickStatsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                QuickStatCard(
                    title: "Active Habits",
                    value: "\(viewModel.analyticsData.activeHabits)",
                    icon: "checkmark.circle.fill",
                    color: .blue
                )
                
                QuickStatCard(
                    title: "Joined Challenges",
                    value: "\(viewModel.analyticsData.joinedChallenges)",
                    icon: "person.2.fill",
                    color: .green
                )
            }
            
            HStack(spacing: 20) {
                QuickStatCard(
                    title: "Current Streaks",
                    value: "\(viewModel.analyticsData.currentStreaks)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                QuickStatCard(
                    title: "Points Earned",
                    value: "\(viewModel.analyticsData.totalPointsEarned)",
                    icon: "star.fill",
                    color: Color(hex: "#F9FF14")
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var timeRangeSelectorView: some View {
        VStack(spacing: 12) {
            Text("Progress Over Time")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: { viewModel.selectTimeRange(range) }) {
                        Text(range.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.selectedTimeRange == range ? .black : .white.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedTimeRange == range ? Color(hex: "#F9FF14") : Color.white.opacity(0.05))
                            .cornerRadius(20)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var progressChartView: some View {
        VStack(spacing: 12) {
            let progressData = viewModel.getProgressForTimeRange()
            
            if !progressData.isEmpty {
                SimpleLineChart(data: progressData)
                    .frame(height: 200)
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No data available")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(height: 200)
            }
        }
    }
    
    private var categoryBreakdownView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Habits by category
                VStack(alignment: .leading, spacing: 8) {
                    Text("Habits")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    ForEach(viewModel.habitCategoryData.prefix(5), id: \.category) { data in
                        CategoryProgressRow(
                            category: data.category.rawValue,
                            icon: data.category.icon,
                            count: data.count,
                            percentage: data.percentage,
                            color: data.category.color
                        )
                    }
                }
                
                // Challenges by category
                VStack(alignment: .leading, spacing: 8) {
                    Text("Challenges")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    ForEach(viewModel.challengeCategoryData.prefix(5), id: \.category) { data in
                        CategoryProgressRow(
                            category: data.category.rawValue,
                            icon: data.category.icon,
                            count: data.count,
                            percentage: data.percentage,
                            color: data.category.color
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var recentAchievementsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Achievements")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    showingAchievements = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#F9FF14"))
            }
            
            if viewModel.recentAchievements.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trophy")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No achievements yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Keep building habits to unlock achievements!")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.recentAchievements.prefix(3)) { achievement in
                        AchievementRow(achievement: achievement)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var insightsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            if viewModel.insights.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No insights available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.insights.prefix(3), id: \.title) { insight in
                        InsightCard(insight: insight)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct CategoryProgressRow: View {
    let category: String
    let icon: String
    let count: Int
    let percentage: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(category)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(width: 60, height: 4)
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(hex: "#F9FF14"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(achievement.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let date = achievement.unlockedDate {
                Text(formatDate(date))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct InsightCard: View {
    let insight: Insight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(insight.type.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(insight.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(insight.type.color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SimpleLineChart: View {
    let data: [ProgressDataPoint]
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.map { $0.value }.max() ?? 1
            let stepX = geometry.size.width / CGFloat(max(data.count - 1, 1))
            
            ZStack {
                // Background
                Rectangle()
                    .fill(Color.white.opacity(0.02))
                    .cornerRadius(12)
                
                // Grid lines
                ForEach(0..<5) { i in
                    let y = geometry.size.height * CGFloat(i) / 4
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height - y))
                    }
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                }
                
                // Line chart
                if data.count > 1 {
                    Path { path in
                        for (index, point) in data.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = geometry.size.height - (CGFloat(point.value) / CGFloat(maxValue)) * geometry.size.height
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color(hex: "#F9FF14"), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    // Data points
                    ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                        let x = CGFloat(index) * stepX
                        let y = geometry.size.height - (CGFloat(point.value) / CGFloat(maxValue)) * geometry.size.height
                        
                        Circle()
                            .fill(Color(hex: "#F9FF14"))
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                    }
                }
                
                // Labels
                VStack {
                    Spacer()
                    
                    HStack {
                        ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                            if index % max(data.count / 4, 1) == 0 {
                                Text(point.label)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                if index < data.count - 1 {
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct AchievementsView: View {
    @ObservedObject var viewModel: ProgressAnalyticsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#050505")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Unlocked achievements
                        if !viewModel.unlockedAchievements.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Unlocked Achievements")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 16) {
                                    ForEach(viewModel.unlockedAchievements) { achievement in
                                        AchievementCard(achievement: achievement, isUnlocked: true)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Locked achievements
                        if !viewModel.lockedAchievements.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Locked Achievements")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 16) {
                                    ForEach(viewModel.lockedAchievements) { achievement in
                                        AchievementCard(achievement: achievement, isUnlocked: false)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(Color(hex: "#F9FF14"))
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.system(size: 30, weight: .medium))
                .foregroundColor(isUnlocked ? Color(hex: "#F9FF14") : .white.opacity(0.3))
            
            Text(achievement.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isUnlocked ? .white : .white.opacity(0.5))
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(isUnlocked ? .white.opacity(0.7) : .white.opacity(0.3))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if isUnlocked, let date = achievement.unlockedDate {
                Text(formatDate(date))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "#F9FF14"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(isUnlocked ? Color.white.opacity(0.05) : Color.white.opacity(0.02))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? Color(hex: "#F9FF14").opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    ProgressAnalyticsView()
        .environmentObject(AnalyticsService(habitsService: HabitsService(), challengesService: ChallengesService()))
}
