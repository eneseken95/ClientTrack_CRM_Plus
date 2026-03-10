//
//  AdminUsersListView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct AdminUsersListView: View {
    @EnvironmentObject var authState: AuthState
    @State private var users: [UserOutDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    var body: some View {
        Group {
            if isLoading && users.isEmpty {
                AdminUserListPlaceholder()
            } else if let error = errorMessage, users.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task {
                            await loadUsers()
                        }
                    }
                }
            } else {
                List(users) { user in
                    NavigationLink {
                        AdminUserDetailView(user: user)
                            .environmentObject(authState)
                    } label: {
                        HStack(spacing: 12) {
                            CachedRemoteImage(url: user.avatar_url, size: 46)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(user.name) \(user.surname ?? "")")
                                    .font(.headline)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if user.role == "admin" {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .background(AppTheme.authBackgroundGradient.ignoresSafeArea())
        .navigationTitle("All Users")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadUsers()
        }
        .refreshable {
            await loadUsers()
        }
    }

    @MainActor
    private func loadUsers() async {
        isLoading = true
        errorMessage = nil
        do {
            users = try await AdminService.listAllUsers()
        } catch {
            errorMessage = "Failed to load users: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
