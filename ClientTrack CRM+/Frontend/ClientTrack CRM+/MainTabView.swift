//
//  MainTabView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authState: AuthState
    @State private var selectedTab = 0
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                ClientListView()
                    .tag(0)
                TasksView()
                    .tag(1)
                EmailsView()
                    .tag(2)
                ProfileAnalyticsView()
                    .tag(3)
                NavigationStack {
                    ProfileView()
                }
                .tag(4)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80)
            }
            HStack {
                tabButton(icon: "person.3.fill", title: "Clients", tag: 0)
                tabButton(icon: "checklist", title: "Tasks", tag: 1)
                tabButton(icon: "envelope.fill", title: "Emails", tag: 2)
                tabButton(icon: "chart.bar.fill", title: "Dashboard", tag: 3)
                Button {
                    selectedTab = 4
                } label: {
                    VStack(spacing: 4) {
                        if (authState.currentUser?.avatar_url) != nil {
                            CachedAvatarView(size: 22)
                                .frame(width: 22, height: 22)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedTab == 4 ? AppTheme.primary : .clear, lineWidth: 2)
                                )
                                .environmentObject(authState)
                        } else {
                            Image(systemName: selectedTab == 4 ? "person.circle.fill" : "person.circle")
                                .font(.system(size: 22))
                                .frame(height: 22)
                                .foregroundColor(selectedTab == 4 ? AppTheme.primary : .gray)
                        }
                        Text("Profile")
                            .font(.caption2)
                            .foregroundColor(selectedTab == 4 ? AppTheme.primary : .gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 0)
            .background(
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Rectangle().fill(AppTheme.authBackgroundGradient.opacity(0.2))
                }
                .ignoresSafeArea(edges: .bottom)
            )
        }
        .ignoresSafeArea(.keyboard)
    }

    private func tabButton(icon: String, title: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .frame(height: 22)
                    .foregroundColor(selectedTab == tag ? AppTheme.primary : .gray)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(selectedTab == tag ? AppTheme.primary : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
