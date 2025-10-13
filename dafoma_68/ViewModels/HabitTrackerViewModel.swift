//
//  HabitTrackerViewModel.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import Foundation
import Combine
import SwiftUI

class HabitTrackerViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var selectedCategory: HabitCategory? = nil
    @Published var showingAddHabit = false
    @Published var showingEditHabit = false
    @Published var selectedHabit: Habit?
    @Published var searchText = ""
    @Published var sortOption: HabitSortOption = .dateCreated
    
    private let habitsService: HabitsService
    private var cancellables = Set<AnyCancellable>()
    
    init(habitsService: HabitsService) {
        self.habitsService = habitsService
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Subscribe to habits changes
        habitsService.$habits
            .assign(to: \.habits, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var filteredHabits: [Habit] {
        var filtered = habits
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { habit in
                habit.title.localizedCaseInsensitiveContains(searchText) ||
                habit.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort habits
        switch sortOption {
        case .dateCreated:
            filtered.sort { $0.createdDate > $1.createdDate }
        case .alphabetical:
            filtered.sort { $0.title < $1.title }
        case .category:
            filtered.sort { $0.category.rawValue < $1.category.rawValue }
        case .completionRate:
            filtered.sort { $0.weeklyCompletionRate > $1.weeklyCompletionRate }
        case .streak:
            filtered.sort { $0.streak > $1.streak }
        }
        
        return filtered
    }
    
    var activeHabits: [Habit] {
        return habits.filter { $0.isActive }
    }
    
    var completedHabitsToday: [Habit] {
        return habits.filter { $0.isCompletedToday }
    }
    
    var todayCompletionRate: Double {
        let active = activeHabits
        guard !active.isEmpty else { return 0.0 }
        
        let completed = completedHabitsToday.count
        return Double(completed) / Double(active.count)
    }
    
    var categoryStats: [HabitCategory: CategoryStats] {
        var stats: [HabitCategory: CategoryStats] = [:]
        
        for category in HabitCategory.allCases {
            let categoryHabits = habits.filter { $0.category == category && $0.isActive }
            let completedToday = categoryHabits.filter { $0.isCompletedToday }.count
            
            stats[category] = CategoryStats(
                total: categoryHabits.count,
                completedToday: completedToday,
                completionRate: categoryHabits.isEmpty ? 0.0 : Double(completedToday) / Double(categoryHabits.count)
            )
        }
        
        return stats
    }
    
    // MARK: - Actions
    
    func addHabit(_ habit: Habit) {
        habitsService.addHabit(habit)
    }
    
    func updateHabit(_ habit: Habit) {
        habitsService.updateHabit(habit)
    }
    
    func deleteHabit(_ habit: Habit) {
        habitsService.deleteHabit(habit)
    }
    
    func toggleHabitCompletion(_ habitId: UUID) {
        habitsService.toggleHabitCompletion(habitId)
    }
    
    func selectHabitForEditing(_ habit: Habit) {
        selectedHabit = habit
        showingEditHabit = true
    }
    
    func clearSelection() {
        selectedHabit = nil
        showingEditHabit = false
    }
    
    func filterByCategory(_ category: HabitCategory?) {
        selectedCategory = category
    }
    
    func clearFilters() {
        selectedCategory = nil
        searchText = ""
    }
}

// MARK: - Supporting Types

enum HabitSortOption: String, CaseIterable {
    case dateCreated = "Date Created"
    case alphabetical = "Alphabetical"
    case category = "Category"
    case completionRate = "Completion Rate"
    case streak = "Streak"
    
    var icon: String {
        switch self {
        case .dateCreated:
            return "calendar"
        case .alphabetical:
            return "textformat.abc"
        case .category:
            return "folder"
        case .completionRate:
            return "percent"
        case .streak:
            return "flame"
        }
    }
}

struct CategoryStats {
    let total: Int
    let completedToday: Int
    let completionRate: Double
}
