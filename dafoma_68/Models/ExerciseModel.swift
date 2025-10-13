//
//  ExerciseModel.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import Foundation
import SwiftUI

struct MindfulnessExercise: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var duration: TimeInterval // in seconds
    var category: ExerciseCategory
    var instructions: [String]
    var audioFileName: String?
    var isCompleted: Bool
    var completionDate: Date?
    var difficulty: ExerciseDifficulty
    var benefits: [String]
    
    init(title: String, description: String, duration: TimeInterval, category: ExerciseCategory, instructions: [String], difficulty: ExerciseDifficulty = .beginner, benefits: [String] = []) {
        self.title = title
        self.description = description
        self.duration = duration
        self.category = category
        self.instructions = instructions
        self.isCompleted = false
        self.difficulty = difficulty
        self.benefits = benefits
    }
    
    var durationString: String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
    
    mutating func markCompleted() {
        isCompleted = true
        completionDate = Date()
    }
    
    mutating func resetCompletion() {
        isCompleted = false
        completionDate = nil
    }
}

enum ExerciseCategory: String, CaseIterable, Codable {
    case breathing = "Breathing"
    case meditation = "Meditation"
    case bodyScanning = "Body Scanning"
    case visualization = "Visualization"
    case gratitude = "Gratitude"
    case mindfulMovement = "Mindful Movement"
    case stressRelief = "Stress Relief"
    case sleep = "Sleep"
    
    var icon: String {
        switch self {
        case .breathing:
            return "wind"
        case .meditation:
            return "figure.mind.and.body"
        case .bodyScanning:
            return "figure.stand"
        case .visualization:
            return "eye.fill"
        case .gratitude:
            return "heart.text.square.fill"
        case .mindfulMovement:
            return "figure.yoga"
        case .stressRelief:
            return "leaf.arrow.circlepath"
        case .sleep:
            return "moon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .breathing:
            return .cyan
        case .meditation:
            return .purple
        case .bodyScanning:
            return .green
        case .visualization:
            return .blue
        case .gratitude:
            return .pink
        case .mindfulMovement:
            return .orange
        case .stressRelief:
            return .mint
        case .sleep:
            return .indigo
        }
    }
}

enum ExerciseDifficulty: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var color: Color {
        switch self {
        case .beginner:
            return .green
        case .intermediate:
            return .orange
        case .advanced:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .beginner:
            return "1.circle.fill"
        case .intermediate:
            return "2.circle.fill"
        case .advanced:
            return "3.circle.fill"
        }
    }
}

// Sample exercises data
extension MindfulnessExercise {
    static let sampleExercises: [MindfulnessExercise] = [
        MindfulnessExercise(
            title: "4-7-8 Breathing",
            description: "A calming breathing technique to reduce anxiety and promote relaxation.",
            duration: 300, // 5 minutes
            category: .breathing,
            instructions: [
                "Sit comfortably with your back straight",
                "Place the tip of your tongue against the ridge behind your upper teeth",
                "Exhale completely through your mouth",
                "Close your mouth and inhale through your nose for 4 counts",
                "Hold your breath for 7 counts",
                "Exhale through your mouth for 8 counts",
                "Repeat this cycle 3-4 times"
            ],
            difficulty: .beginner,
            benefits: ["Reduces anxiety", "Improves sleep", "Lowers stress"]
        ),
        MindfulnessExercise(
            title: "Body Scan Meditation",
            description: "A progressive relaxation technique that helps you connect with your body.",
            duration: 900, // 15 minutes
            category: .bodyScanning,
            instructions: [
                "Lie down comfortably on your back",
                "Close your eyes and take three deep breaths",
                "Start by focusing on your toes",
                "Slowly move your attention up through each part of your body",
                "Notice any sensations without judgment",
                "Spend 30 seconds on each body part",
                "End by taking three deep breaths"
            ],
            difficulty: .intermediate,
            benefits: ["Improves body awareness", "Reduces tension", "Promotes relaxation"]
        ),
        MindfulnessExercise(
            title: "Loving-Kindness Meditation",
            description: "Cultivate compassion and positive emotions towards yourself and others.",
            duration: 600, // 10 minutes
            category: .meditation,
            instructions: [
                "Sit comfortably and close your eyes",
                "Begin by directing loving-kindness towards yourself",
                "Repeat: 'May I be happy, may I be healthy, may I be at peace'",
                "Extend these wishes to a loved one",
                "Then to a neutral person",
                "Finally to someone you have difficulty with",
                "End by extending loving-kindness to all beings"
            ],
            difficulty: .intermediate,
            benefits: ["Increases compassion", "Reduces negative emotions", "Improves relationships"]
        ),
        MindfulnessExercise(
            title: "Gratitude Reflection",
            description: "Focus on appreciation and positive aspects of your life.",
            duration: 180, // 3 minutes
            category: .gratitude,
            instructions: [
                "Find a quiet, comfortable place to sit",
                "Take three deep breaths to center yourself",
                "Think of three things you're grateful for today",
                "For each item, spend time really feeling the gratitude",
                "Notice how gratitude feels in your body",
                "End with a moment of appreciation for this practice"
            ],
            difficulty: .beginner,
            benefits: ["Improves mood", "Increases life satisfaction", "Reduces stress"]
        ),
        MindfulnessExercise(
            title: "Mountain Visualization",
            description: "Use imagery to cultivate stability and groundedness.",
            duration: 720, // 12 minutes
            category: .visualization,
            instructions: [
                "Sit with your spine straight like a mountain",
                "Close your eyes and breathe naturally",
                "Visualize yourself as a majestic mountain",
                "Feel your base rooted firmly in the earth",
                "Notice how weather passes over you without changing you",
                "Embody the mountain's stability and permanence",
                "Carry this sense of groundedness with you"
            ],
            difficulty: .advanced,
            benefits: ["Builds resilience", "Increases stability", "Improves focus"]
        )
    ]
}
