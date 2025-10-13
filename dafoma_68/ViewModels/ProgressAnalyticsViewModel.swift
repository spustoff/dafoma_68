//
//  ProgressAnalyticsViewModel.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import Foundation
import Combine
import SwiftUI

class ProgressAnalyticsViewModel: ObservableObject {
    @Published var analyticsData: AnalyticsData = AnalyticsData()
    @Published var selectedTimeRange: TimeRange = .week
    @Published var selectedMetric: AnalyticsMetric = .habits
    @Published var showingAchievements = false
    @Published var showingDetailedStats = false
    
    private let analyticsService: AnalyticsService
    private var cancellables = Set<AnyCancellable>()
    
    init(analyticsService: AnalyticsService) {
        self.analyticsService = analyticsService
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        analyticsService.$analyticsData
            .assign(to: \.analyticsData, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var overallProgress: Double {
        let habitProgress = analyticsData.habitCompletionRate
        let challengeProgress = analyticsData.challengeCompletionRate
        return (habitProgress + challengeProgress) / 2.0
    }
    
    var weeklyData: [WeeklyProgressData] {
        return analyticsData.weeklyProgress
    }
    
    var monthlyData: [MonthlyProgressData] {
        return analyticsData.monthlyProgress
    }
    
    var recentAchievements: [Achievement] {
        return analyticsData.achievements.filter { $0.isUnlocked }.sorted { 
            ($0.unlockedDate ?? Date.distantPast) > ($1.unlockedDate ?? Date.distantPast)
        }.prefix(5).map { $0 }
    }
    
    var unlockedAchievements: [Achievement] {
        return analyticsData.achievements.filter { $0.isUnlocked }
    }
    
    var lockedAchievements: [Achievement] {
        return analyticsData.achievements.filter { !$0.isUnlocked }
    }
    
    var habitCategoryData: [(category: HabitCategory, count: Int, percentage: Double)] {
        let total = analyticsData.totalHabits
        guard total > 0 else { return [] }
        
        return analyticsData.habitsByCategory.map { (category, count) in
            let percentage = Double(count) / Double(total)
            return (category: category, count: count, percentage: percentage)
        }.sorted { $0.count > $1.count }
    }
    
    var challengeCategoryData: [(category: ChallengeCategory, count: Int, percentage: Double)] {
        let total = analyticsData.totalChallenges
        guard total > 0 else { return [] }
        
        return analyticsData.challengesByCategory.map { (category, count) in
            let percentage = Double(count) / Double(total)
            return (category: category, count: count, percentage: percentage)
        }.sorted { $0.count > $1.count }
    }
    
    var streakData: StreakData {
        return StreakData(
            current: analyticsData.currentStreaks,
            longest: analyticsData.longestHabitStreak,
            active: analyticsData.currentStreaks > 0
        )
    }
    
    var productivityScore: Int {
        let habitScore = Int(analyticsData.habitCompletionRate * 40)
        let challengeScore = Int(analyticsData.challengeCompletionRate * 30)
        let streakScore = min(analyticsData.longestHabitStreak * 2, 20)
        let achievementScore = min(unlockedAchievements.count * 2, 10)
        
        return habitScore + challengeScore + streakScore + achievementScore
    }
    
    var insights: [Insight] {
        var insights: [Insight] = []
        
        // Habit insights
        if analyticsData.habitCompletionRate > 0.8 {
            insights.append(Insight(
                title: "Excellent Habit Consistency!",
                description: "You're completing \(Int(analyticsData.habitCompletionRate * 100))% of your habits. Keep up the great work!",
                type: .positive,
                icon: "star.fill"
            ))
        } else if analyticsData.habitCompletionRate < 0.5 {
            insights.append(Insight(
                title: "Room for Improvement",
                description: "Consider reducing the number of habits or adjusting their difficulty to improve consistency.",
                type: .suggestion,
                icon: "lightbulb.fill"
            ))
        }
        
        // Streak insights
        if analyticsData.longestHabitStreak >= 30 {
            insights.append(Insight(
                title: "Streak Master!",
                description: "Your longest streak is \(analyticsData.longestHabitStreak) days. You're building strong habits!",
                type: .positive,
                icon: "flame.fill"
            ))
        }
        
        // Challenge insights
        if analyticsData.challengeCompletionRate > 0.7 {
            insights.append(Insight(
                title: "Challenge Champion",
                description: "You're excelling at community challenges with a \(Int(analyticsData.challengeCompletionRate * 100))% completion rate!",
                type: .positive,
                icon: "trophy.fill"
            ))
        }
        
        // Points insights
        if analyticsData.totalPointsEarned >= 500 {
            insights.append(Insight(
                title: "Point Collector",
                description: "You've earned \(analyticsData.totalPointsEarned) points from challenges. Amazing dedication!",
                type: .positive,
                icon: "star.circle.fill"
            ))
        }
        
        return insights
    }
    
    // MARK: - Actions
    
    func selectTimeRange(_ range: TimeRange) {
        selectedTimeRange = range
    }
    
    func selectMetric(_ metric: AnalyticsMetric) {
        selectedMetric = metric
    }
    
    func showAchievements() {
        showingAchievements = true
    }
    
    func hideAchievements() {
        showingAchievements = false
    }
    
    func showDetailedStats() {
        showingDetailedStats = true
    }
    
    func hideDetailedStats() {
        showingDetailedStats = false
    }
    
    func getProgressForTimeRange() -> [ProgressDataPoint] {
        switch selectedTimeRange {
        case .week:
            return weeklyData.map { data in
                ProgressDataPoint(
                    date: data.weekStart,
                    value: Double(data.totalActivities),
                    label: formatWeekLabel(data.weekStart)
                )
            }
        case .month:
            return monthlyData.map { data in
                ProgressDataPoint(
                    date: data.monthStart,
                    value: Double(data.totalActivities),
                    label: formatMonthLabel(data.monthStart)
                )
            }
        case .year:
            // For year view, aggregate monthly data by quarters
            return aggregateQuarterlyData()
        }
    }
    
    private func aggregateQuarterlyData() -> [ProgressDataPoint] {
        let calendar = Calendar.current
        var quarterlyData: [Date: Double] = [:]
        
        for monthData in monthlyData {
            let quarter = calendar.dateInterval(of: .quarter, for: monthData.monthStart)?.start ?? monthData.monthStart
            quarterlyData[quarter, default: 0] += Double(monthData.totalActivities)
        }
        
        return quarterlyData.map { (date, value) in
            ProgressDataPoint(
                date: date,
                value: value,
                label: formatQuarterLabel(date)
            )
        }.sorted { $0.date < $1.date }
    }
    
    private func formatWeekLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatMonthLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func formatQuarterLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        let quarter = (calendar.component(.month, from: date) - 1) / 3 + 1
        let year = calendar.component(.year, from: date)
        return "Q\(quarter) '\(String(year).suffix(2))"
    }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var icon: String {
        switch self {
        case .week:
            return "calendar.day.timeline.left"
        case .month:
            return "calendar"
        case .year:
            return "calendar.badge.clock"
        }
    }
}

enum AnalyticsMetric: String, CaseIterable {
    case habits = "Habits"
    case challenges = "Challenges"
    case overall = "Overall"
    
    var icon: String {
        switch self {
        case .habits:
            return "checkmark.circle"
        case .challenges:
            return "trophy"
        case .overall:
            return "chart.line.uptrend.xyaxis"
        }
    }
}

struct StreakData {
    let current: Int
    let longest: Int
    let active: Bool
}

struct Insight {
    let title: String
    let description: String
    let type: InsightType
    let icon: String
}

enum InsightType {
    case positive
    case suggestion
    case warning
    
    var color: Color {
        switch self {
        case .positive:
            return .green
        case .suggestion:
            return .blue
        case .warning:
            return .orange
        }
    }
}

struct ProgressDataPoint {
    let date: Date
    let value: Double
    let label: String
}
