//
//  AnalyticsService.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import Foundation
import Combine

class AnalyticsService: ObservableObject {
    @Published var analyticsData: AnalyticsData = AnalyticsData()
    
    private var habitsService: HabitsService
    private var challengesService: ChallengesService
    private var cancellables = Set<AnyCancellable>()
    
    init(habitsService: HabitsService, challengesService: ChallengesService) {
        self.habitsService = habitsService
        self.challengesService = challengesService
        
        setupSubscriptions()
        updateAnalytics()
    }
    
    private func setupSubscriptions() {
        // Update analytics when habits change
        habitsService.$habits
            .sink { [weak self] _ in
                self?.updateAnalytics()
            }
            .store(in: &cancellables)
        
        // Update analytics when challenges change
        challengesService.$challenges
            .sink { [weak self] _ in
                self?.updateAnalytics()
            }
            .store(in: &cancellables)
        
        challengesService.$userParticipations
            .sink { [weak self] _ in
                self?.updateAnalytics()
            }
            .store(in: &cancellables)
    }
    
    private func updateAnalytics() {
        analyticsData = AnalyticsData(
            // Habit Analytics
            totalHabits: habitsService.habits.count,
            activeHabits: habitsService.getActiveHabits().count,
            completedHabitsToday: habitsService.getCompletedHabitsToday().count,
            habitCompletionRate: habitsService.getTotalCompletionRate(),
            weeklyHabitCompletionRate: habitsService.getWeeklyCompletionRate(),
            longestHabitStreak: habitsService.getLongestStreak(),
            currentStreaks: habitsService.getCurrentStreaks().count,
            
            // Challenge Analytics
            totalChallenges: challengesService.challenges.count,
            joinedChallenges: challengesService.getJoinedChallenges().count,
            completedChallenges: challengesService.getCompletedChallenges().count,
            challengeCompletionRate: challengesService.getTotalCompletionRate(),
            totalPointsEarned: challengesService.getTotalPointsEarned(),
            
            // Category Breakdown
            habitsByCategory: getHabitsByCategory(),
            challengesByCategory: getChallengesByCategory(),
            
            // Time-based Analytics
            weeklyProgress: getWeeklyProgress(),
            monthlyProgress: getMonthlyProgress(),
            
            // Achievement Data
            achievements: getAchievements()
        )
    }
    
    private func getHabitsByCategory() -> [HabitCategory: Int] {
        var categoryCount: [HabitCategory: Int] = [:]
        
        for category in HabitCategory.allCases {
            categoryCount[category] = habitsService.getHabitsForCategory(category).count
        }
        
        return categoryCount
    }
    
    private func getChallengesByCategory() -> [ChallengeCategory: Int] {
        var categoryCount: [ChallengeCategory: Int] = [:]
        
        for category in ChallengeCategory.allCases {
            categoryCount[category] = challengesService.getChallengesForCategory(category).count
        }
        
        return categoryCount
    }
    
    private func getWeeklyProgress() -> [WeeklyProgressData] {
        var weeklyData: [WeeklyProgressData] = []
        let calendar = Calendar.current
        
        // Get last 4 weeks of data
        for weekOffset in 0..<4 {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: Date()) else { continue }
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else { continue }
            
            let habitsCompleted = getHabitsCompletedInPeriod(start: weekInterval.start, end: weekInterval.end)
            let challengeTasksCompleted = getChallengeTasksCompletedInPeriod(start: weekInterval.start, end: weekInterval.end)
            
            let progressData = WeeklyProgressData(
                weekStart: weekInterval.start,
                habitsCompleted: habitsCompleted,
                challengeTasksCompleted: challengeTasksCompleted,
                totalActivities: habitsCompleted + challengeTasksCompleted
            )
            
            weeklyData.append(progressData)
        }
        
        return weeklyData.reversed() // Show oldest to newest
    }
    
    private func getMonthlyProgress() -> [MonthlyProgressData] {
        var monthlyData: [MonthlyProgressData] = []
        let calendar = Calendar.current
        
        // Get last 6 months of data
        for monthOffset in 0..<6 {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: Date()) else { continue }
            guard let monthInterval = calendar.dateInterval(of: .month, for: monthStart) else { continue }
            
            let habitsCompleted = getHabitsCompletedInPeriod(start: monthInterval.start, end: monthInterval.end)
            let challengesCompleted = getChallengesCompletedInPeriod(start: monthInterval.start, end: monthInterval.end)
            
            let progressData = MonthlyProgressData(
                monthStart: monthInterval.start,
                habitsCompleted: habitsCompleted,
                challengesCompleted: challengesCompleted,
                totalActivities: habitsCompleted + challengesCompleted
            )
            
            monthlyData.append(progressData)
        }
        
        return monthlyData.reversed() // Show oldest to newest
    }
    
    private func getHabitsCompletedInPeriod(start: Date, end: Date) -> Int {
        return habitsService.habits.reduce(0) { total, habit in
            let completionsInPeriod = habit.completions.filter { completion in
                completion >= start && completion <= end
            }
            return total + completionsInPeriod.count
        }
    }
    
    private func getChallengeTasksCompletedInPeriod(start: Date, end: Date) -> Int {
        return challengesService.challenges.reduce(0) { total, challenge in
            let completedTasks = challenge.dailyTasks.filter { task in
                guard let completionDate = task.completionDate else { return false }
                return completionDate >= start && completionDate <= end && task.isCompleted
            }
            return total + completedTasks.count
        }
    }
    
    private func getChallengesCompletedInPeriod(start: Date, end: Date) -> Int {
        return challengesService.challenges.filter { challenge in
            challenge.isCompleted && challenge.endDate >= start && challenge.endDate <= end
        }.count
    }
    
    private func getAchievements() -> [Achievement] {
        var achievements: [Achievement] = []
        
        // Habit-based achievements
        let totalHabits = habitsService.habits.count
        if totalHabits >= 1 {
            achievements.append(Achievement(title: "First Step", description: "Created your first habit", icon: "star.fill", isUnlocked: true))
        }
        if totalHabits >= 5 {
            achievements.append(Achievement(title: "Habit Builder", description: "Created 5 habits", icon: "building.2.fill", isUnlocked: true))
        }
        if totalHabits >= 10 {
            achievements.append(Achievement(title: "Habit Master", description: "Created 10 habits", icon: "crown.fill", isUnlocked: true))
        }
        
        // Streak-based achievements
        let longestStreak = habitsService.getLongestStreak()
        if longestStreak >= 7 {
            achievements.append(Achievement(title: "Week Warrior", description: "Maintained a 7-day streak", icon: "flame.fill", isUnlocked: true))
        }
        if longestStreak >= 30 {
            achievements.append(Achievement(title: "Monthly Master", description: "Maintained a 30-day streak", icon: "calendar.badge.checkmark", isUnlocked: true))
        }
        if longestStreak >= 100 {
            achievements.append(Achievement(title: "Century Club", description: "Maintained a 100-day streak", icon: "trophy.fill", isUnlocked: true))
        }
        
        // Challenge-based achievements
        let completedChallenges = challengesService.getCompletedChallenges().count
        if completedChallenges >= 1 {
            achievements.append(Achievement(title: "Challenge Accepted", description: "Completed your first challenge", icon: "checkmark.seal.fill", isUnlocked: true))
        }
        if completedChallenges >= 5 {
            achievements.append(Achievement(title: "Challenge Champion", description: "Completed 5 challenges", icon: "medal.fill", isUnlocked: true))
        }
        
        // Points-based achievements
        let totalPoints = challengesService.getTotalPointsEarned()
        if totalPoints >= 100 {
            achievements.append(Achievement(title: "Point Collector", description: "Earned 100 points", icon: "star.circle.fill", isUnlocked: true))
        }
        if totalPoints >= 500 {
            achievements.append(Achievement(title: "Point Master", description: "Earned 500 points", icon: "star.square.fill", isUnlocked: true))
        }
        
        return achievements
    }
}

// MARK: - Data Models

struct AnalyticsData {
    // Habit Analytics
    var totalHabits: Int = 0
    var activeHabits: Int = 0
    var completedHabitsToday: Int = 0
    var habitCompletionRate: Double = 0.0
    var weeklyHabitCompletionRate: Double = 0.0
    var longestHabitStreak: Int = 0
    var currentStreaks: Int = 0
    
    // Challenge Analytics
    var totalChallenges: Int = 0
    var joinedChallenges: Int = 0
    var completedChallenges: Int = 0
    var challengeCompletionRate: Double = 0.0
    var totalPointsEarned: Int = 0
    
    // Category Breakdown
    var habitsByCategory: [HabitCategory: Int] = [:]
    var challengesByCategory: [ChallengeCategory: Int] = [:]
    
    // Time-based Analytics
    var weeklyProgress: [WeeklyProgressData] = []
    var monthlyProgress: [MonthlyProgressData] = []
    
    // Achievement Data
    var achievements: [Achievement] = []
}

struct WeeklyProgressData: Identifiable {
    let id = UUID()
    let weekStart: Date
    let habitsCompleted: Int
    let challengeTasksCompleted: Int
    let totalActivities: Int
}

struct MonthlyProgressData: Identifiable {
    let id = UUID()
    let monthStart: Date
    let habitsCompleted: Int
    let challengesCompleted: Int
    let totalActivities: Int
}

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
    let unlockedDate: Date?
    
    init(title: String, description: String, icon: String, isUnlocked: Bool, unlockedDate: Date? = nil) {
        self.title = title
        self.description = description
        self.icon = icon
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate ?? (isUnlocked ? Date() : nil)
    }
}
