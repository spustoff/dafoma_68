//
//  ChallengeModel.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import Foundation
import SwiftUI

struct Challenge: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var category: ChallengeCategory
    var duration: Int // in days
    var startDate: Date
    var endDate: Date
    var participants: [Participant]
    var dailyTasks: [DailyTask]
    var isActive: Bool
    var difficulty: ChallengeDifficulty
    var rewards: [String]
    var progress: Double // 0.0 to 1.0
    
    init(title: String, description: String, category: ChallengeCategory, duration: Int, difficulty: ChallengeDifficulty = .medium, rewards: [String] = []) {
        self.title = title
        self.description = description
        self.category = category
        self.duration = duration
        self.startDate = Date()
        self.endDate = Calendar.current.date(byAdding: .day, value: duration, to: Date()) ?? Date()
        self.participants = []
        self.dailyTasks = []
        self.isActive = true
        self.difficulty = difficulty
        self.rewards = rewards
        self.progress = 0.0
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: endDate)
        
        return calendar.dateComponents([.day], from: today, to: end).day ?? 0
    }
    
    var isCompleted: Bool {
        return progress >= 1.0 || Date() > endDate
    }
    
    var participantCount: Int {
        return participants.count
    }
    
    mutating func updateProgress() {
        let completedTasks = dailyTasks.filter { $0.isCompleted }.count
        let totalTasks = dailyTasks.count
        
        if totalTasks > 0 {
            progress = Double(completedTasks) / Double(totalTasks)
        }
    }
    
    mutating func joinChallenge(participant: Participant) {
        if !participants.contains(where: { $0.id == participant.id }) {
            participants.append(participant)
        }
    }
    
    mutating func leaveChallenge(participantId: UUID) {
        participants.removeAll { $0.id == participantId }
    }
}

struct Participant: Identifiable, Codable {
    let id = UUID()
    var name: String
    var avatar: String // System image name or emoji
    var joinDate: Date
    var completedTasks: Int
    var streak: Int
    var isCurrentUser: Bool
    
    init(name: String, avatar: String = "person.circle.fill", isCurrentUser: Bool = false) {
        self.name = name
        self.avatar = avatar
        self.joinDate = Date()
        self.completedTasks = 0
        self.streak = 0
        self.isCurrentUser = isCurrentUser
    }
}

struct DailyTask: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var targetDate: Date
    var isCompleted: Bool
    var completionDate: Date?
    var points: Int
    
    init(title: String, description: String, targetDate: Date, points: Int = 10) {
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.isCompleted = false
        self.points = points
    }
    
    mutating func markCompleted() {
        isCompleted = true
        completionDate = Date()
    }
    
    mutating func markIncomplete() {
        isCompleted = false
        completionDate = nil
    }
}

enum ChallengeCategory: String, CaseIterable, Codable {
    case fitness = "Fitness"
    case mindfulness = "Mindfulness"
    case productivity = "Productivity"
    case creativity = "Creativity"
    case health = "Health"
    case learning = "Learning"
    case social = "Social"
    case environmental = "Environmental"
    
    var icon: String {
        switch self {
        case .fitness:
            return "figure.run"
        case .mindfulness:
            return "leaf.fill"
        case .productivity:
            return "checkmark.circle.fill"
        case .creativity:
            return "paintbrush.fill"
        case .health:
            return "heart.fill"
        case .learning:
            return "book.fill"
        case .social:
            return "person.2.fill"
        case .environmental:
            return "globe.americas.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .fitness:
            return .orange
        case .mindfulness:
            return .green
        case .productivity:
            return .blue
        case .creativity:
            return .purple
        case .health:
            return .red
        case .learning:
            return .indigo
        case .social:
            return .pink
        case .environmental:
            return .mint
        }
    }
}

enum ChallengeDifficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case extreme = "Extreme"
    
    var color: Color {
        switch self {
        case .easy:
            return .green
        case .medium:
            return .yellow
        case .hard:
            return .orange
        case .extreme:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .easy:
            return "1.circle.fill"
        case .medium:
            return "2.circle.fill"
        case .hard:
            return "3.circle.fill"
        case .extreme:
            return "flame.fill"
        }
    }
}

// Sample challenges data
extension Challenge {
    static let sampleChallenges: [Challenge] = [
        Challenge(
            title: "30-Day Mindfulness Journey",
            description: "Commit to 10 minutes of daily mindfulness practice for 30 days. Build a sustainable meditation habit.",
            category: .mindfulness,
            duration: 30,
            difficulty: .medium,
            rewards: ["Mindfulness Master Badge", "Stress Reduction Achievement", "Inner Peace Trophy"]
        ),
        Challenge(
            title: "7-Day Gratitude Challenge",
            description: "Write down 3 things you're grateful for each day. Cultivate a positive mindset.",
            category: .mindfulness,
            duration: 7,
            difficulty: .easy,
            rewards: ["Gratitude Guru Badge", "Positivity Boost Achievement"]
        ),
        Challenge(
            title: "21-Day Fitness Kickstart",
            description: "Exercise for at least 30 minutes daily. Build strength, endurance, and healthy habits.",
            category: .fitness,
            duration: 21,
            difficulty: .medium,
            rewards: ["Fitness Warrior Badge", "Strength Builder Achievement", "Endurance Master Trophy"]
        ),
        Challenge(
            title: "14-Day Creative Sprint",
            description: "Spend 1 hour daily on a creative project. Unlock your artistic potential.",
            category: .creativity,
            duration: 14,
            difficulty: .medium,
            rewards: ["Creative Genius Badge", "Artistic Vision Achievement"]
        ),
        Challenge(
            title: "5-Day Digital Detox",
            description: "Limit screen time to essential use only. Reconnect with the real world.",
            category: .health,
            duration: 5,
            difficulty: .hard,
            rewards: ["Digital Minimalist Badge", "Real World Explorer Achievement"]
        )
    ]
}
