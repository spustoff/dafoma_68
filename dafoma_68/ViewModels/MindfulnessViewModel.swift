//
//  MindfulnessViewModel.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import Foundation
import Combine
import SwiftUI

class MindfulnessViewModel: ObservableObject {
    @Published var exercises: [MindfulnessExercise] = []
    @Published var selectedCategory: ExerciseCategory? = nil
    @Published var selectedDifficulty: ExerciseDifficulty? = nil
    @Published var searchText = ""
    @Published var sortOption: ExerciseSortOption = .duration
    @Published var showingExerciseDetail = false
    @Published var selectedExercise: MindfulnessExercise?
    @Published var isExerciseActive = false
    @Published var exerciseProgress: Double = 0.0
    @Published var remainingTime: TimeInterval = 0
    
    private let userDefaults = UserDefaults.standard
    private let exercisesKey = "SavedExercises"
    private var exerciseTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadExercises()
    }
    
    // MARK: - Computed Properties
    
    var filteredExercises: [MindfulnessExercise] {
        var filtered = exercises
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by difficulty
        if let difficulty = selectedDifficulty {
            filtered = filtered.filter { $0.difficulty == difficulty }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.title.localizedCaseInsensitiveContains(searchText) ||
                exercise.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort exercises
        switch sortOption {
        case .duration:
            filtered.sort { $0.duration < $1.duration }
        case .alphabetical:
            filtered.sort { $0.title < $1.title }
        case .category:
            filtered.sort { $0.category.rawValue < $1.category.rawValue }
        case .difficulty:
            filtered.sort { $0.difficulty.rawValue < $1.difficulty.rawValue }
        case .completed:
            filtered.sort { $0.isCompleted && !$1.isCompleted }
        }
        
        return filtered
    }
    
    var completedExercises: [MindfulnessExercise] {
        return exercises.filter { $0.isCompleted }
    }
    
    var totalMindfulnessTime: TimeInterval {
        return completedExercises.reduce(0) { $0 + $1.duration }
    }
    
    var categoryStats: [ExerciseCategory: ExerciseCategoryStats] {
        var stats: [ExerciseCategory: ExerciseCategoryStats] = [:]
        
        for category in ExerciseCategory.allCases {
            let categoryExercises = exercises.filter { $0.category == category }
            let completed = categoryExercises.filter { $0.isCompleted }.count
            let totalTime = categoryExercises.filter { $0.isCompleted }.reduce(0) { $0 + $1.duration }
            
            stats[category] = ExerciseCategoryStats(
                total: categoryExercises.count,
                completed: completed,
                totalTime: totalTime,
                completionRate: categoryExercises.isEmpty ? 0.0 : Double(completed) / Double(categoryExercises.count)
            )
        }
        
        return stats
    }
    
    var exerciseStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        while hasExerciseOnDate(currentDate) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    // MARK: - Actions
    
    func startExercise(_ exercise: MindfulnessExercise) {
        selectedExercise = exercise
        remainingTime = exercise.duration
        exerciseProgress = 0.0
        isExerciseActive = true
        showingExerciseDetail = true
        startTimer()
    }
    
    func pauseExercise() {
        isExerciseActive = false
        exerciseTimer?.invalidate()
    }
    
    func resumeExercise() {
        isExerciseActive = true
        startTimer()
    }
    
    func stopExercise() {
        isExerciseActive = false
        exerciseTimer?.invalidate()
        exerciseProgress = 0.0
        remainingTime = selectedExercise?.duration ?? 0
    }
    
    func completeExercise() {
        guard let exercise = selectedExercise,
              let index = exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        
        exercises[index].markCompleted()
        isExerciseActive = false
        exerciseTimer?.invalidate()
        exerciseProgress = 1.0
        remainingTime = 0
        
        saveExercises()
    }
    
    func resetExerciseCompletion(_ exerciseId: UUID) {
        if let index = exercises.firstIndex(where: { $0.id == exerciseId }) {
            exercises[index].resetCompletion()
            saveExercises()
        }
    }
    
    func filterByCategory(_ category: ExerciseCategory?) {
        selectedCategory = category
    }
    
    func filterByDifficulty(_ difficulty: ExerciseDifficulty?) {
        selectedDifficulty = difficulty
    }
    
    func clearFilters() {
        selectedCategory = nil
        selectedDifficulty = nil
        searchText = ""
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        exerciseTimer?.invalidate()
        
        exerciseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let exercise = self.selectedExercise else { return }
            
            if self.remainingTime > 0 {
                self.remainingTime -= 1
                self.exerciseProgress = 1.0 - (self.remainingTime / exercise.duration)
            } else {
                self.completeExercise()
            }
        }
    }
    
    private func hasExerciseOnDate(_ date: Date) -> Bool {
        return exercises.contains { exercise in
            guard let completionDate = exercise.completionDate else { return false }
            return Calendar.current.isDate(completionDate, inSameDayAs: date)
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveExercises() {
        do {
            let data = try JSONEncoder().encode(exercises)
            userDefaults.set(data, forKey: exercisesKey)
        } catch {
            print("Failed to save exercises: \(error)")
        }
    }
    
    private func loadExercises() {
        guard let data = userDefaults.data(forKey: exercisesKey) else {
            exercises = MindfulnessExercise.sampleExercises
            saveExercises()
            return
        }
        
        do {
            exercises = try JSONDecoder().decode([MindfulnessExercise].self, from: data)
        } catch {
            print("Failed to load exercises: \(error)")
            exercises = MindfulnessExercise.sampleExercises
            saveExercises()
        }
    }
    
    // MARK: - Reset Data
    
    func resetAllData() {
        exercises.removeAll()
        userDefaults.removeObject(forKey: exercisesKey)
        exercises = MindfulnessExercise.sampleExercises
        saveExercises()
    }
    
    deinit {
        exerciseTimer?.invalidate()
    }
}

// MARK: - Supporting Types

enum ExerciseSortOption: String, CaseIterable {
    case duration = "Duration"
    case alphabetical = "Alphabetical"
    case category = "Category"
    case difficulty = "Difficulty"
    case completed = "Completed"
    
    var icon: String {
        switch self {
        case .duration:
            return "clock"
        case .alphabetical:
            return "textformat.abc"
        case .category:
            return "folder"
        case .difficulty:
            return "chart.bar"
        case .completed:
            return "checkmark.circle"
        }
    }
}

struct ExerciseCategoryStats {
    let total: Int
    let completed: Int
    let totalTime: TimeInterval
    let completionRate: Double
}
