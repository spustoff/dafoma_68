//
//  CommunityChallengesViewModel.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import Foundation
import Combine
import SwiftUI

class CommunityChallengesViewModel: ObservableObject {
    @Published var challenges: [Challenge] = []
    @Published var userParticipations: [UUID] = []
    @Published var selectedTab: ChallengeTab = .available
    @Published var selectedCategory: ChallengeCategory? = nil
    @Published var selectedDifficulty: ChallengeDifficulty? = nil
    @Published var searchText = ""
    @Published var sortOption: ChallengeSortOption = .startDate
    @Published var showingChallengeDetail = false
    @Published var selectedChallenge: Challenge?
    
    private let challengesService: ChallengesService
    private var cancellables = Set<AnyCancellable>()
    
    init(challengesService: ChallengesService) {
        self.challengesService = challengesService
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Subscribe to challenges changes
        challengesService.$challenges
            .assign(to: \.challenges, on: self)
            .store(in: &cancellables)
        
        challengesService.$userParticipations
            .assign(to: \.userParticipations, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var filteredChallenges: [Challenge] {
        var filtered: [Challenge] = []
        
        // Filter by tab
        switch selectedTab {
        case .available:
            filtered = challenges.filter { !userParticipations.contains($0.id) && $0.isActive }
        case .joined:
            filtered = challenges.filter { userParticipations.contains($0.id) }
        case .completed:
            filtered = challenges.filter { $0.isCompleted }
        case .all:
            filtered = challenges
        }
        
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
            filtered = filtered.filter { challenge in
                challenge.title.localizedCaseInsensitiveContains(searchText) ||
                challenge.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort challenges
        switch sortOption {
        case .startDate:
            filtered.sort { $0.startDate > $1.startDate }
        case .endDate:
            filtered.sort { $0.endDate < $1.endDate }
        case .alphabetical:
            filtered.sort { $0.title < $1.title }
        case .participants:
            filtered.sort { $0.participantCount > $1.participantCount }
        case .difficulty:
            filtered.sort { $0.difficulty.rawValue < $1.difficulty.rawValue }
        case .progress:
            filtered.sort { $0.progress > $1.progress }
        }
        
        return filtered
    }
    
    var joinedChallenges: [Challenge] {
        return challenges.filter { userParticipations.contains($0.id) }
    }
    
    var completedChallenges: [Challenge] {
        return challenges.filter { $0.isCompleted }
    }
    
    var activeChallenges: [Challenge] {
        return challenges.filter { $0.isActive && Date() <= $0.endDate }
    }
    
    var totalPointsEarned: Int {
        return joinedChallenges.reduce(0) { total, challenge in
            let completedTasks = challenge.dailyTasks.filter { $0.isCompleted }
            return total + completedTasks.reduce(0) { $0 + $1.points }
        }
    }
    
    var averageCompletionRate: Double {
        let joined = joinedChallenges
        guard !joined.isEmpty else { return 0.0 }
        
        let totalProgress = joined.reduce(0.0) { $0 + $1.progress }
        return totalProgress / Double(joined.count)
    }
    
    var categoryStats: [ChallengeCategory: ChallengeCategoryStats] {
        var stats: [ChallengeCategory: ChallengeCategoryStats] = [:]
        
        for category in ChallengeCategory.allCases {
            let categoryJoined = joinedChallenges.filter { $0.category == category }
            let categoryCompleted = categoryJoined.filter { $0.isCompleted }
            let totalPoints = categoryJoined.reduce(0) { total, challenge in
                let completedTasks = challenge.dailyTasks.filter { $0.isCompleted }
                return total + completedTasks.reduce(0) { $0 + $1.points }
            }
            
            stats[category] = ChallengeCategoryStats(
                joined: categoryJoined.count,
                completed: categoryCompleted.count,
                totalPoints: totalPoints,
                completionRate: categoryJoined.isEmpty ? 0.0 : Double(categoryCompleted.count) / Double(categoryJoined.count)
            )
        }
        
        return stats
    }
    
    var upcomingTasks: [DailyTask] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        
        return joinedChallenges.flatMap { challenge in
            challenge.dailyTasks.filter { task in
                !task.isCompleted && task.targetDate >= today && task.targetDate < tomorrow
            }
        }
    }
    
    // MARK: - Actions
    
    func joinChallenge(_ challengeId: UUID) {
        challengesService.joinChallenge(challengeId)
    }
    
    func leaveChallenge(_ challengeId: UUID) {
        challengesService.leaveChallenge(challengeId)
    }
    
    func completeTask(_ challengeId: UUID, taskId: UUID) {
        challengesService.completeTask(challengeId, taskId: taskId)
    }
    
    func uncompleteTask(_ challengeId: UUID, taskId: UUID) {
        challengesService.uncompleteTask(challengeId, taskId: taskId)
    }
    
    func selectChallenge(_ challenge: Challenge) {
        selectedChallenge = challenge
        showingChallengeDetail = true
    }
    
    func clearSelection() {
        selectedChallenge = nil
        showingChallengeDetail = false
    }
    
    func switchTab(_ tab: ChallengeTab) {
        selectedTab = tab
    }
    
    func filterByCategory(_ category: ChallengeCategory?) {
        selectedCategory = category
    }
    
    func filterByDifficulty(_ difficulty: ChallengeDifficulty?) {
        selectedDifficulty = difficulty
    }
    
    func clearFilters() {
        selectedCategory = nil
        selectedDifficulty = nil
        searchText = ""
    }
    
    func isUserParticipating(in challengeId: UUID) -> Bool {
        return userParticipations.contains(challengeId)
    }
    
    func getChallengeProgress(_ challengeId: UUID) -> Double {
        guard let challenge = challenges.first(where: { $0.id == challengeId }) else { return 0.0 }
        return challenge.progress
    }
    
    func getDaysRemaining(_ challengeId: UUID) -> Int {
        guard let challenge = challenges.first(where: { $0.id == challengeId }) else { return 0 }
        return challenge.daysRemaining
    }
}

// MARK: - Supporting Types

enum ChallengeTab: String, CaseIterable {
    case available = "Available"
    case joined = "Joined"
    case completed = "Completed"
    case all = "All"
    
    var icon: String {
        switch self {
        case .available:
            return "plus.circle"
        case .joined:
            return "person.circle"
        case .completed:
            return "checkmark.circle"
        case .all:
            return "list.bullet"
        }
    }
}

enum ChallengeSortOption: String, CaseIterable {
    case startDate = "Start Date"
    case endDate = "End Date"
    case alphabetical = "Alphabetical"
    case participants = "Participants"
    case difficulty = "Difficulty"
    case progress = "Progress"
    
    var icon: String {
        switch self {
        case .startDate:
            return "calendar"
        case .endDate:
            return "calendar.badge.clock"
        case .alphabetical:
            return "textformat.abc"
        case .participants:
            return "person.2"
        case .difficulty:
            return "chart.bar"
        case .progress:
            return "percent"
        }
    }
}

struct ChallengeCategoryStats {
    let joined: Int
    let completed: Int
    let totalPoints: Int
    let completionRate: Double
}
