//
//  HabitsService.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import Foundation
import Combine

class HabitsService: ObservableObject {
    @Published var habits: [Habit] = []
    
    private let userDefaults = UserDefaults.standard
    private let habitsKey = "SavedHabits"
    
    init() {
        loadHabits()
    }
    
    // MARK: - Habit Management
    
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            saveHabits()
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        saveHabits()
    }
    
    func toggleHabitCompletion(_ habitId: UUID) {
        if let index = habits.firstIndex(where: { $0.id == habitId }) {
            if habits[index].isCompletedToday {
                habits[index].markIncomplete()
            } else {
                habits[index].markCompleted()
            }
            saveHabits()
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveHabits() {
        do {
            let data = try JSONEncoder().encode(habits)
            userDefaults.set(data, forKey: habitsKey)
        } catch {
            print("Failed to save habits: \(error)")
        }
    }
    
    private func loadHabits() {
        guard let data = userDefaults.data(forKey: habitsKey) else {
            // Load sample habits for first-time users
            loadSampleHabits()
            return
        }
        
        do {
            habits = try JSONDecoder().decode([Habit].self, from: data)
        } catch {
            print("Failed to load habits: \(error)")
            loadSampleHabits()
        }
    }
    
    private func loadSampleHabits() {
        habits = [
            Habit(title: "Morning Meditation", description: "Start the day with 10 minutes of mindfulness", category: .mindfulness, targetFrequency: 7),
            Habit(title: "Daily Exercise", description: "30 minutes of physical activity", category: .fitness, targetFrequency: 5),
            Habit(title: "Read for 30 minutes", description: "Expand knowledge through reading", category: .learning, targetFrequency: 7),
            Habit(title: "Drink 8 glasses of water", description: "Stay hydrated throughout the day", category: .health, targetFrequency: 7),
            Habit(title: "Write in journal", description: "Reflect on the day's experiences", category: .personal, targetFrequency: 7)
        ]
        saveHabits()
    }
    
    // MARK: - Analytics
    
    func getHabitsForCategory(_ category: HabitCategory) -> [Habit] {
        return habits.filter { $0.category == category }
    }
    
    func getActiveHabits() -> [Habit] {
        return habits.filter { $0.isActive }
    }
    
    func getCompletedHabitsToday() -> [Habit] {
        return habits.filter { $0.isCompletedToday }
    }
    
    func getTotalCompletionRate() -> Double {
        let activeHabits = getActiveHabits()
        guard !activeHabits.isEmpty else { return 0.0 }
        
        let completedToday = getCompletedHabitsToday().count
        return Double(completedToday) / Double(activeHabits.count)
    }
    
    func getWeeklyCompletionRate() -> Double {
        let activeHabits = getActiveHabits()
        guard !activeHabits.isEmpty else { return 0.0 }
        
        let totalRate = activeHabits.reduce(0.0) { $0 + $1.weeklyCompletionRate }
        return totalRate / Double(activeHabits.count)
    }
    
    func getLongestStreak() -> Int {
        return habits.map { $0.bestStreak }.max() ?? 0
    }
    
    func getCurrentStreaks() -> [Habit] {
        return habits.filter { $0.streak > 0 }.sorted { $0.streak > $1.streak }
    }
    
    // MARK: - Reset Data
    
    func resetAllData() {
        habits.removeAll()
        userDefaults.removeObject(forKey: habitsKey)
    }
}
