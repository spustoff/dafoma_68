//
//  HabitTrackerView.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import SwiftUI

struct HabitTrackerView: View {
    @EnvironmentObject var habitsService: HabitsService
    @StateObject private var viewModel = HabitTrackerViewModel(habitsService: HabitsService())
    @State private var showingAddHabit = false
    @State private var selectedHabit: Habit?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#050505")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with stats
                    headerView
                    
                    // Search and filters
                    searchAndFiltersView
                    
                    // Habits list
                    habitsListView
                }
            }
        }
        .onAppear {
            // The viewModel will use the environment object automatically through Combine
        }
        .sheet(isPresented: $showingAddHabit) {
            AddEditHabitView(habit: nil) { habit in
                viewModel.addHabit(habit)
            }
        }
        .sheet(item: $selectedHabit) { habit in
            AddEditHabitView(habit: habit) { updatedHabit in
                viewModel.updateHabit(updatedHabit)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 20) {
            // Title and add button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Habits")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Today's Progress")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: { showingAddHabit = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(Color(hex: "#F9FF14"))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            
            // Progress overview
            progressOverviewView
        }
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
    
    private var progressOverviewView: some View {
        VStack(spacing: 16) {
            // Completion rate circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: viewModel.todayCompletionRate)
                    .stroke(Color(hex: "#F9FF14"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: viewModel.todayCompletionRate)
                
                VStack(spacing: 4) {
                    Text("\(Int(viewModel.todayCompletionRate * 100))%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Complete")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Stats row
            HStack(spacing: 30) {
                StatItem(
                    value: "\(viewModel.completedHabitsToday.count)",
                    label: "Completed",
                    color: Color(hex: "#F9FF14")
                )
                
                StatItem(
                    value: "\(viewModel.activeHabits.count)",
                    label: "Active",
                    color: .white.opacity(0.7)
                )
                
                StatItem(
                    value: "\(viewModel.habits.map { $0.streak }.max() ?? 0)",
                    label: "Best Streak",
                    color: .orange
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var searchAndFiltersView: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.5))
                
                TextField("Search habits...", text: $viewModel.searchText)
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
                    
                    ForEach(HabitCategory.allCases, id: \.self) { category in
                        FilterChip(
                            title: category.rawValue,
                            isSelected: viewModel.selectedCategory == category,
                            action: { viewModel.filterByCategory(category) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 16)
    }
    
    private var habitsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredHabits) { habit in
                    HabitRowView(
                        habit: habit,
                        onToggle: { viewModel.toggleHabitCompletion(habit.id) },
                        onEdit: { selectedHabit = habit },
                        onDelete: { viewModel.deleteHabit(habit) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "#F9FF14") : Color.white.opacity(0.05))
                .cornerRadius(20)
        }
    }
}

struct HabitRowView: View {
    let habit: Habit
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Completion button
            Button(action: onToggle) {
                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(habit.isCompletedToday ? Color(hex: "#F9FF14") : .white.opacity(0.3))
            }
            
            // Habit info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(habit.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .strikethrough(habit.isCompletedToday)
                    
                    Spacer()
                    
                    // Category icon
                    Image(systemName: habit.category.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(habit.category.color)
                }
                
                Text(habit.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                
                // Progress info
                HStack {
                    if habit.streak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            
                            Text("\(habit.streak) day streak")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(Int(habit.weeklyCompletionRate * 100))% this week")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Menu button
            Menu {
                Button("Edit", action: onEdit)
                Button("Delete", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 30, height: 30)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct AddEditHabitView: View {
    let habit: Habit?
    let onSave: (Habit) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory = HabitCategory.health
    @State private var targetFrequency = 7
    @State private var selectedColor = "#F9FF14"
    
    private let colors = ["#F9FF14", "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#050505")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Title field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Habit Name")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        TextField("Enter habit name", text: $title)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                    }
                    
                    // Description field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        TextField("Enter description", text: $description)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                    }
                    
                    // Category selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(HabitCategory.allCases, id: \.self) { category in
                                    CategoryChip(
                                        category: category,
                                        isSelected: selectedCategory == category,
                                        action: { selectedCategory = category }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    // Target frequency
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Frequency (per week)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Stepper(value: $targetFrequency, in: 1...7) {
                            Text("\(targetFrequency) times per week")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // Color selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                Button(action: { selectedColor = color }) {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle(habit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHabit()
                    }
                    .foregroundColor(Color(hex: "#F9FF14"))
                    .disabled(title.isEmpty)
                }
            }
        }
        .onAppear {
            if let habit = habit {
                title = habit.title
                description = habit.description
                selectedCategory = habit.category
                targetFrequency = habit.targetFrequency
                selectedColor = habit.color
            }
        }
    }
    
    private func saveHabit() {
        let newHabit = Habit(
            title: title,
            description: description,
            category: selectedCategory,
            targetFrequency: targetFrequency,
            color: selectedColor
        )
        
        onSave(newHabit)
        dismiss()
    }
}

struct CategoryChip: View {
    let category: HabitCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : .white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: "#F9FF14") : Color.white.opacity(0.05))
            .cornerRadius(20)
        }
    }
}


#Preview {
    HabitTrackerView()
        .environmentObject(HabitsService())
}
