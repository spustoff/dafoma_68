//
//  MindfulnessExercisesView.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import SwiftUI

struct MindfulnessExercisesView: View {
    @StateObject private var viewModel = MindfulnessViewModel()
    @State private var selectedExercise: MindfulnessExercise?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#050505")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Search and filters
                    searchAndFiltersView
                    
                    // Exercises list
                    exercisesListView
                }
            }
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise, viewModel: viewModel)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 20) {
            // Title
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mindfulness")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Find your inner peace")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Streak indicator
                if viewModel.exerciseStreak > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                        
                        Text("\(viewModel.exerciseStreak)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 20)
            
            // Stats overview
            statsOverviewView
        }
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
    
    private var statsOverviewView: some View {
        HStack(spacing: 30) {
            StatItem(
                value: "\(viewModel.completedExercises.count)",
                label: "Completed",
                color: Color(hex: "#F9FF14")
            )
            
            StatItem(
                value: formatTime(viewModel.totalMindfulnessTime),
                label: "Total Time",
                color: .green
            )
            
            StatItem(
                value: "\(viewModel.exercises.count)",
                label: "Available",
                color: .white.opacity(0.7)
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var searchAndFiltersView: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.5))
                
                TextField("Search exercises...", text: $viewModel.searchText)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All",
                        isSelected: viewModel.selectedCategory == nil,
                        action: { viewModel.filterByCategory(nil) }
                    )
                    
                    ForEach(ExerciseCategory.allCases, id: \.self) { category in
                        FilterChip(
                            title: category.rawValue,
                            isSelected: viewModel.selectedCategory == category,
                            action: { viewModel.filterByCategory(category) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Difficulty filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All Levels",
                        isSelected: viewModel.selectedDifficulty == nil,
                        action: { viewModel.filterByDifficulty(nil) }
                    )
                    
                    ForEach(ExerciseDifficulty.allCases, id: \.self) { difficulty in
                        FilterChip(
                            title: difficulty.rawValue,
                            isSelected: viewModel.selectedDifficulty == difficulty,
                            action: { viewModel.filterByDifficulty(difficulty) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 16)
    }
    
    private var exercisesListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredExercises) { exercise in
                    ExerciseRowView(exercise: exercise) {
                        selectedExercise = exercise
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        }
    }
}

struct ExerciseRowView: View {
    let exercise: MindfulnessExercise
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(exercise.category.color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: exercise.category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(exercise.category.color)
                }
                
                // Exercise info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(exercise.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if exercise.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#F9FF14"))
                        }
                    }
                    
                    Text(exercise.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        // Duration
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text(exercise.durationString)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        // Difficulty
                        HStack(spacing: 4) {
                            Image(systemName: exercise.difficulty.icon)
                                .font(.system(size: 10))
                                .foregroundColor(exercise.difficulty.color)
                            
                            Text(exercise.difficulty.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(exercise.difficulty.color)
                        }
                    }
                }
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExerciseDetailView: View {
    let exercise: MindfulnessExercise
    @ObservedObject var viewModel: MindfulnessViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentInstructionIndex = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#050505")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.isExerciseActive && viewModel.selectedExercise?.id == exercise.id {
                        // Active exercise view
                        activeExerciseView
                    } else {
                        // Exercise details view
                        exerciseDetailsView
                    }
                }
            }
        }
    }
    
    private var exerciseDetailsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(exercise.category.color.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: exercise.category.icon)
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(exercise.category.color)
                    }
                    
                    Text(exercise.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(exercise.description)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 20)
                
                // Exercise info
                HStack(spacing: 30) {
                    InfoItem(
                        icon: "clock",
                        title: "Duration",
                        value: exercise.durationString,
                        color: .blue
                    )
                    
                    InfoItem(
                        icon: exercise.difficulty.icon,
                        title: "Difficulty",
                        value: exercise.difficulty.rawValue,
                        color: exercise.difficulty.color
                    )
                    
                    InfoItem(
                        icon: exercise.category.icon,
                        title: "Category",
                        value: exercise.category.rawValue,
                        color: exercise.category.color
                    )
                }
                .padding(.horizontal, 20)
                
                // Benefits
                if !exercise.benefits.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Benefits")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            ForEach(exercise.benefits, id: \.self) { benefit in
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "#F9FF14"))
                                    
                                    Text(benefit)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Instructions")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 12) {
                        ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "#F9FF14"))
                                    .frame(width: 24, height: 24)
                                    .background(Color(hex: "#F9FF14").opacity(0.1))
                                    .clipShape(Circle())
                                
                                Text(instruction)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineSpacing(2)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Start button
                Button(action: { viewModel.startExercise(exercise) }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Start Exercise")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#F9FF14"))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var activeExerciseView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: viewModel.exerciseProgress)
                    .stroke(Color(hex: "#F9FF14"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.exerciseProgress)
                
                VStack(spacing: 8) {
                    Text(formatTime(viewModel.remainingTime))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text("remaining")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Exercise title
            Text(exercise.title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Control buttons
            HStack(spacing: 30) {
                Button(action: { viewModel.stopExercise() }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.red.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    if viewModel.isExerciseActive {
                        viewModel.pauseExercise()
                    } else {
                        viewModel.resumeExercise()
                    }
                }) {
                    Image(systemName: viewModel.isExerciseActive ? "pause.fill" : "play.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "#F9FF14"))
                        .clipShape(Circle())
                }
                
                Button(action: { viewModel.completeExercise() }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.green.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            
            Spacer()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    viewModel.stopExercise()
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct InfoItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    MindfulnessExercisesView()
}
