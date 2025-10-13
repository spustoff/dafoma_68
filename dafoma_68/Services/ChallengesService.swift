//
//  ChallengesService.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import Foundation
import Combine

class ChallengesService: ObservableObject {
    @Published var challenges: [Challenge] = []
    @Published var userParticipations: [UUID] = [] // Challenge IDs user has joined
    
    private let userDefaults = UserDefaults.standard
    private let challengesKey = "SavedChallenges"
    private let participationsKey = "UserParticipations"
    
    init() {
        loadChallenges()
        loadUserParticipations()
    }
    
    // MARK: - Challenge Management
    
    func addChallenge(_ challenge: Challenge) {
        challenges.append(challenge)
        saveChallenges()
    }
    
    func updateChallenge(_ challenge: Challenge) {
        if let index = challenges.firstIndex(where: { $0.id == challenge.id }) {
            challenges[index] = challenge
            saveChallenges()
        }
    }
    
    func deleteChallenge(_ challenge: Challenge) {
        challenges.removeAll { $0.id == challenge.id }
        userParticipations.removeAll { $0 == challenge.id }
        saveChallenges()
        saveUserParticipations()
    }
    
    func joinChallenge(_ challengeId: UUID) {
        if !userParticipations.contains(challengeId) {
            userParticipations.append(challengeId)
            
            // Add current user as participant
            if let index = challenges.firstIndex(where: { $0.id == challengeId }) {
                let currentUser = Participant(name: "You", avatar: "person.circle.fill", isCurrentUser: true)
                challenges[index].joinChallenge(participant: currentUser)
                saveChallenges()
            }
            
            saveUserParticipations()
        }
    }
    
    func leaveChallenge(_ challengeId: UUID) {
        userParticipations.removeAll { $0 == challengeId }
        
        // Remove current user from participants
        if let index = challenges.firstIndex(where: { $0.id == challengeId }) {
            challenges[index].participants.removeAll { $0.isCurrentUser }
            saveChallenges()
        }
        
        saveUserParticipations()
    }
    
    func completeTask(_ challengeId: UUID, taskId: UUID) {
        if let challengeIndex = challenges.firstIndex(where: { $0.id == challengeId }),
           let taskIndex = challenges[challengeIndex].dailyTasks.firstIndex(where: { $0.id == taskId }) {
            challenges[challengeIndex].dailyTasks[taskIndex].markCompleted()
            challenges[challengeIndex].updateProgress()
            saveChallenges()
        }
    }
    
    func uncompleteTask(_ challengeId: UUID, taskId: UUID) {
        if let challengeIndex = challenges.firstIndex(where: { $0.id == challengeId }),
           let taskIndex = challenges[challengeIndex].dailyTasks.firstIndex(where: { $0.id == taskId }) {
            challenges[challengeIndex].dailyTasks[taskIndex].markIncomplete()
            challenges[challengeIndex].updateProgress()
            saveChallenges()
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveChallenges() {
        do {
            let data = try JSONEncoder().encode(challenges)
            userDefaults.set(data, forKey: challengesKey)
        } catch {
            print("Failed to save challenges: \(error)")
        }
    }
    
    private func loadChallenges() {
        guard let data = userDefaults.data(forKey: challengesKey) else {
            loadSampleChallenges()
            return
        }
        
        do {
            challenges = try JSONDecoder().decode([Challenge].self, from: data)
        } catch {
            print("Failed to load challenges: \(error)")
            loadSampleChallenges()
        }
    }
    
    private func saveUserParticipations() {
        do {
            let data = try JSONEncoder().encode(userParticipations)
            userDefaults.set(data, forKey: participationsKey)
        } catch {
            print("Failed to save user participations: \(error)")
        }
    }
    
    private func loadUserParticipations() {
        guard let data = userDefaults.data(forKey: participationsKey) else { return }
        
        do {
            userParticipations = try JSONDecoder().decode([UUID].self, from: data)
        } catch {
            print("Failed to load user participations: \(error)")
        }
    }
    
    private func loadSampleChallenges() {
        var sampleChallenges = Challenge.sampleChallenges
        
        // Add sample participants and daily tasks
        for i in 0..<sampleChallenges.count {
            // Add sample participants
            let sampleParticipants = [
                Participant(name: "Alex", avatar: "person.fill"),
                Participant(name: "Sarah", avatar: "person.2.fill"),
                Participant(name: "Mike", avatar: "person.3.fill"),
                Participant(name: "Emma", avatar: "person.crop.circle.fill")
            ]
            
            let randomParticipants = Array(sampleParticipants.shuffled().prefix(Int.random(in: 2...4)))
            sampleChallenges[i].participants = randomParticipants
            
            // Add sample daily tasks
            let challenge = sampleChallenges[i]
            var dailyTasks: [DailyTask] = []
            
            for day in 0..<challenge.duration {
                let taskDate = Calendar.current.date(byAdding: .day, value: day, to: challenge.startDate) ?? Date()
                let task = DailyTask(
                    title: "Day \(day + 1) Task",
                    description: getTaskDescription(for: challenge.category, day: day + 1),
                    targetDate: taskDate,
                    points: 10
                )
                dailyTasks.append(task)
            }
            
            sampleChallenges[i].dailyTasks = dailyTasks
        }
        
        challenges = sampleChallenges
        saveChallenges()
    }
    
    private func getTaskDescription(for category: ChallengeCategory, day: Int) -> String {
        switch category {
        case .mindfulness:
            return "Complete \(10 + day) minutes of mindfulness practice"
        case .fitness:
            return "Exercise for \(30 + day * 2) minutes"
        case .creativity:
            return "Spend 1 hour on your creative project"
        case .health:
            return "Avoid screens for \(2 + day) hours"
        case .productivity:
            return "Complete your daily productivity goals"
        case .learning:
            return "Learn something new for 30 minutes"
        case .social:
            return "Connect with someone meaningful"
        case .environmental:
            return "Take an eco-friendly action"
        }
    }
    
    // MARK: - Analytics
    
    func getActiveChallenges() -> [Challenge] {
        return challenges.filter { $0.isActive && Date() <= $0.endDate }
    }
    
    func getJoinedChallenges() -> [Challenge] {
        return challenges.filter { userParticipations.contains($0.id) }
    }
    
    func getAvailableChallenges() -> [Challenge] {
        return challenges.filter { !userParticipations.contains($0.id) && $0.isActive }
    }
    
    func getCompletedChallenges() -> [Challenge] {
        return challenges.filter { $0.isCompleted }
    }
    
    func getChallengesForCategory(_ category: ChallengeCategory) -> [Challenge] {
        return challenges.filter { $0.category == category }
    }
    
    func getTotalCompletionRate() -> Double {
        let joinedChallenges = getJoinedChallenges()
        guard !joinedChallenges.isEmpty else { return 0.0 }
        
        let totalProgress = joinedChallenges.reduce(0.0) { $0 + $1.progress }
        return totalProgress / Double(joinedChallenges.count)
    }
    
    func getTotalPointsEarned() -> Int {
        let joinedChallenges = getJoinedChallenges()
        return joinedChallenges.reduce(0) { total, challenge in
            let completedTasks = challenge.dailyTasks.filter { $0.isCompleted }
            return total + completedTasks.reduce(0) { $0 + $1.points }
        }
    }
    
    // MARK: - Reset Data
    
    func resetAllData() {
        challenges.removeAll()
        userParticipations.removeAll()
        userDefaults.removeObject(forKey: challengesKey)
        userDefaults.removeObject(forKey: participationsKey)
    }
}
