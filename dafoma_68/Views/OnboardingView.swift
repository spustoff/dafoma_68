//
//  OnboardingView.swift
//  dafoma_68
//
//  Created by Вячеслав on 10/13/25.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var showingMainApp = false
    
    private let pages = OnboardingPage.allPages
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#050505")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Bottom Section
                VStack(spacing: 24) {
                    // Page Indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color(hex: "#F9FF14") : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Navigation Buttons
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button("Back") {
                                withAnimation(.easeInOut) {
                                    currentPage -= 1
                                }
                            }
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 16, weight: .medium))
                        }
                        
                        Spacer()
                        
                        if currentPage < pages.count - 1 {
                            Button("Next") {
                                withAnimation(.easeInOut) {
                                    currentPage += 1
                                }
                            }
                            .foregroundColor(Color(hex: "#F9FF14"))
                            .font(.system(size: 16, weight: .semibold))
                        } else {
                            Button("Get Started") {
                                completeOnboarding()
                            }
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .bold))
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#F9FF14"))
                            .cornerRadius(25)
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $showingMainApp) {
            ContentView()
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        showingMainApp = true
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "#F9FF14").opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.icon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(Color(hex: "#F9FF14"))
            }
            
            // Content
            VStack(spacing: 24) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    
    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to\nHabitSpherePari",
            description: "Transform your daily life with personalized habit tracking, mindfulness exercises, and community challenges.",
            icon: "sparkles"
        ),
        OnboardingPage(
            title: "Track Your\nHabits",
            description: "Create and organize habits by categories. Monitor your progress with beautiful analytics and maintain streaks.",
            icon: "checkmark.circle.fill"
        ),
        OnboardingPage(
            title: "Mindfulness\nExercises",
            description: "Access guided meditation, breathing exercises, and relaxation techniques to improve your mental wellness.",
            icon: "leaf.fill"
        ),
        OnboardingPage(
            title: "Community\nChallenges",
            description: "Join challenges with others, share your progress, and stay motivated through community support.",
            icon: "person.2.fill"
        ),
        OnboardingPage(
            title: "Progress\nAnalytics",
            description: "Visualize your journey with detailed insights, achievements, and personalized recommendations.",
            icon: "chart.line.uptrend.xyaxis"
        )
    ]
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    OnboardingView()
}
