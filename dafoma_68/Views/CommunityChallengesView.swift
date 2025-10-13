//
//  CommunityChallengesView.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import SwiftUI

struct CommunityChallengesView: View {
    @EnvironmentObject var challengesService: ChallengesService
    @StateObject private var viewModel = CommunityChallengesViewModel(challengesService: ChallengesService())
    @State private var selectedChallenge: Challenge?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#050505")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Tab selector
                    tabSelectorView
                    
                    // Search and filters
                    searchAndFiltersView
                    
                    // Challenges list
                    challengesListView
                }
            }
        }
        .sheet(item: $selectedChallenge) { challenge in
            ChallengeDetailView(challenge: challenge, viewModel: viewModel)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 20) {
            // Title
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Challenges")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Join the community")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Points indicator
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#F9FF14"))
                    
                    Text("\(viewModel.totalPointsEarned)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#F9FF14"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "#F9FF14").opacity(0.1))
                .cornerRadius(16)
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
                value: "\(viewModel.joinedChallenges.count)",
                label: "Joined",
                color: Color(hex: "#F9FF14")
            )
            
            StatItem(
                value: "\(viewModel.completedChallenges.count)",
                label: "Completed",
                color: .green
            )
            
            StatItem(
                value: "\(Int(viewModel.averageCompletionRate * 100))%",
                label: "Success Rate",
                color: .blue
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var tabSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ChallengeTab.allCases, id: \.self) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: viewModel.selectedTab == tab,
                        count: getTabCount(tab),
                        action: { viewModel.switchTab(tab) }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }
    
    private var searchAndFiltersView: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.5))
                
                TextField("Search challenges...", text: $viewModel.searchText)
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
                    
                    ForEach(ChallengeCategory.allCases, id: \.self) { category in
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
    
    private var challengesListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredChallenges) { challenge in
                    ChallengeRowView(
                        challenge: challenge,
                        isJoined: viewModel.isUserParticipating(in: challenge.id),
                        onTap: { selectedChallenge = challenge },
                        onJoin: { viewModel.joinChallenge(challenge.id) },
                        onLeave: { viewModel.leaveChallenge(challenge.id) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private func getTabCount(_ tab: ChallengeTab) -> Int {
        switch tab {
        case .available:
            return viewModel.challenges.filter { !viewModel.userParticipations.contains($0.id) && $0.isActive }.count
        case .joined:
            return viewModel.joinedChallenges.count
        case .completed:
            return viewModel.completedChallenges.count
        case .all:
            return viewModel.challenges.count
        }
    }
}

struct TabButton: View {
    let tab: ChallengeTab
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(tab.rawValue)
                    .font(.system(size: 14, weight: .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isSelected ? .black : Color(hex: "#F9FF14"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color(hex: "#F9FF14") : Color(hex: "#F9FF14").opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .black : .white.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color(hex: "#F9FF14") : Color.white.opacity(0.05))
            .cornerRadius(20)
        }
    }
}

struct ChallengeRowView: View {
    let challenge: Challenge
    let isJoined: Bool
    let onTap: () -> Void
    let onJoin: () -> Void
    let onLeave: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Header
                HStack(spacing: 12) {
                    // Category icon
                    ZStack {
                        Circle()
                            .fill(challenge.category.color.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: challenge.category.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(challenge.category.color)
                    }
                    
                    // Challenge info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(challenge.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Difficulty badge
                            HStack(spacing: 4) {
                                Image(systemName: challenge.difficulty.icon)
                                    .font(.system(size: 10))
                                    .foregroundColor(challenge.difficulty.color)
                                
                                Text(challenge.difficulty.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(challenge.difficulty.color)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(challenge.difficulty.color.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Text(challenge.description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                // Progress and stats
                VStack(spacing: 8) {
                    if isJoined {
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 4)
                                    .cornerRadius(2)
                                
                                Rectangle()
                                    .fill(Color(hex: "#F9FF14"))
                                    .frame(width: geometry.size.width * challenge.progress, height: 4)
                                    .cornerRadius(2)
                            }
                        }
                        .frame(height: 4)
                    }
                    
                    HStack {
                        // Duration
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("\(challenge.duration) days")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        // Participants
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("\(challenge.participantCount)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        if isJoined {
                            if challenge.daysRemaining > 0 {
                                Text("\(challenge.daysRemaining) days left")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "#F9FF14"))
                            } else {
                                Text("Completed")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                // Action button
                HStack {
                    Spacer()
                    
                    Button(action: isJoined ? onLeave : onJoin) {
                        Text(isJoined ? "Leave" : "Join")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isJoined ? .red : .black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(isJoined ? Color.red.opacity(0.1) : Color(hex: "#F9FF14"))
                            .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ChallengeDetailView: View {
    let challenge: Challenge
    @ObservedObject var viewModel: CommunityChallengesViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#050505")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(challenge.category.color.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: challenge.category.icon)
                                    .font(.system(size: 40, weight: .light))
                                    .foregroundColor(challenge.category.color)
                            }
                            
                            Text(challenge.title)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(challenge.description)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 20)
                        
                        // Challenge info
                        HStack(spacing: 30) {
                            InfoItem(
                                icon: "calendar",
                                title: "Duration",
                                value: "\(challenge.duration) days",
                                color: .blue
                            )
                            
                            InfoItem(
                                icon: "person.2",
                                title: "Participants",
                                value: "\(challenge.participantCount)",
                                color: .green
                            )
                            
                            InfoItem(
                                icon: challenge.difficulty.icon,
                                title: "Difficulty",
                                value: challenge.difficulty.rawValue,
                                color: challenge.difficulty.color
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Progress (if joined)
                        if viewModel.isUserParticipating(in: challenge.id) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Progress")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                VStack(spacing: 8) {
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.white.opacity(0.1))
                                                .frame(height: 8)
                                                .cornerRadius(4)
                                            
                                            Rectangle()
                                                .fill(Color(hex: "#F9FF14"))
                                                .frame(width: geometry.size.width * challenge.progress, height: 8)
                                                .cornerRadius(4)
                                        }
                                    }
                                    .frame(height: 8)
                                    
                                    HStack {
                                        Text("\(Int(challenge.progress * 100))% Complete")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        if challenge.daysRemaining > 0 {
                                            Text("\(challenge.daysRemaining) days remaining")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white.opacity(0.7))
                                        } else {
                                            Text("Challenge completed!")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Daily tasks (if joined)
                        if viewModel.isUserParticipating(in: challenge.id) && !challenge.dailyTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Daily Tasks")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                VStack(spacing: 8) {
                                    ForEach(challenge.dailyTasks.prefix(5)) { task in
                                        DailyTaskRow(
                                            task: task,
                                            onToggle: {
                                                if task.isCompleted {
                                                    viewModel.uncompleteTask(challenge.id, taskId: task.id)
                                                } else {
                                                    viewModel.completeTask(challenge.id, taskId: task.id)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Rewards
                        if !challenge.rewards.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Rewards")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                VStack(spacing: 8) {
                                    ForEach(challenge.rewards, id: \.self) { reward in
                                        HStack(spacing: 12) {
                                            Image(systemName: "trophy.fill")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(Color(hex: "#F9FF14"))
                                            
                                            Text(reward)
                                                .font(.system(size: 14, weight: .regular))
                                                .foregroundColor(.white.opacity(0.8))
                                            
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Action button
                        Button(action: {
                            if viewModel.isUserParticipating(in: challenge.id) {
                                viewModel.leaveChallenge(challenge.id)
                            } else {
                                viewModel.joinChallenge(challenge.id)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: viewModel.isUserParticipating(in: challenge.id) ? "minus.circle.fill" : "plus.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text(viewModel.isUserParticipating(in: challenge.id) ? "Leave Challenge" : "Join Challenge")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(viewModel.isUserParticipating(in: challenge.id) ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(viewModel.isUserParticipating(in: challenge.id) ? Color.red.opacity(0.8) : Color(hex: "#F9FF14"))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
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
}

struct DailyTaskRow: View {
    let task: DailyTask
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(task.isCompleted ? Color(hex: "#F9FF14") : .white.opacity(0.3))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .strikethrough(task.isCompleted)
                
                Text(task.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#F9FF14"))
                
                Text("\(task.points)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#F9FF14"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    CommunityChallengesView()
        .environmentObject(ChallengesService())
}
