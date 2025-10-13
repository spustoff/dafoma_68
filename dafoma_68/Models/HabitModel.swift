//
//  HabitModel.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import Foundation
import SwiftUI

struct Habit: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var category: HabitCategory
    var targetFrequency: Int // times per week
    var createdDate: Date
    var completions: [Date] // Array of completion dates
    var isActive: Bool
    var streak: Int
    var bestStreak: Int
    var color: String // Hex color string
    
    init(title: String, description: String, category: HabitCategory, targetFrequency: Int = 7, color: String = "#F9FF14") {
        self.title = title
        self.description = description
        self.category = category
        self.targetFrequency = targetFrequency
        self.createdDate = Date()
        self.completions = []
        self.isActive = true
        self.streak = 0
        self.bestStreak = 0
        self.color = color
    }
    
    // Check if habit was completed today
    var isCompletedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return completions.contains { completion in
            Calendar.current.isDate(completion, inSameDayAs: today)
        }
    }
    
    // Get completion rate for current week
    var weeklyCompletionRate: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        let weekCompletions = completions.filter { completion in
            completion >= startOfWeek && completion <= now
        }
        
        return min(Double(weekCompletions.count) / Double(targetFrequency), 1.0)
    }
    
    // Calculate current streak
    mutating func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var currentStreak = 0
        var checkDate = today
        
        // Count consecutive days with completions
        while completions.contains(where: { calendar.isDate($0, inSameDayAs: checkDate) }) {
            currentStreak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        self.streak = currentStreak
        self.bestStreak = max(self.bestStreak, currentStreak)
    }
    
    // Mark habit as completed for today
    mutating func markCompleted() {
        let today = Date()
        if !isCompletedToday {
            completions.append(today)
            updateStreak()
        }
    }
    
    // Remove today's completion
    mutating func markIncomplete() {
        let today = Calendar.current.startOfDay(for: Date())
        completions.removeAll { completion in
            Calendar.current.isDate(completion, inSameDayAs: today)
        }
        updateStreak()
    }
}

enum HabitCategory: String, CaseIterable, Codable {
    case health = "Health"
    case productivity = "Productivity"
    case creativity = "Creativity"
    case mindfulness = "Mindfulness"
    case fitness = "Fitness"
    case learning = "Learning"
    case social = "Social"
    case personal = "Personal"
    
    var icon: String {
        switch self {
        case .health:
            return "heart.fill"
        case .productivity:
            return "checkmark.circle.fill"
        case .creativity:
            return "paintbrush.fill"
        case .mindfulness:
            return "leaf.fill"
        case .fitness:
            return "figure.run"
        case .learning:
            return "book.fill"
        case .social:
            return "person.2.fill"
        case .personal:
            return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .health:
            return .red
        case .productivity:
            return .blue
        case .creativity:
            return .purple
        case .mindfulness:
            return .green
        case .fitness:
            return .orange
        case .learning:
            return .indigo
        case .social:
            return .pink
        case .personal:
            return .yellow
        }
    }
}
