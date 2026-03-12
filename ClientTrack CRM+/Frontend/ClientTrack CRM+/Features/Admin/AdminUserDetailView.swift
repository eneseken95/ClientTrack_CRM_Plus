//
//  AdminUserDetailView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct AdminUserDetailView: View {
    let user: UserOutDTO
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) private var dismiss
    @State private var clients: [ClientDTO] = []
    @State private var currentPage = 1
    @State private var totalClients = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.subtleGradient)
                            .frame(width: 110, height: 110)
                            .blur(radius: 20)
                            .frame(width: 150, height: 150)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        CachedRemoteImage(url: user.avatar_url, size: 124)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [AppTheme.primary.opacity(0.3), AppTheme.accent.opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                                    .frame(width: 124, height: 124)
                            )
                    }
                    VStack(spacing: 4) {
                        Text("\(user.name) \(user.surname ?? "")")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text(user.email)
                            .font(.body)
                            .foregroundColor(AppTheme.textSecondary)
                        if user.role == "admin" {
                            Text(user.role.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.primary.opacity(0.12))
                                )
                                .foregroundColor(AppTheme.primary)
                                .padding(.top, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 0)
                .listRowBackground(Color.clear)
            }
            Section {
                HStack {
                    Text("Name")
                    Spacer()
                    Text("\(user.name) \(user.surname ?? "")")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Email")
                    Spacer()
                    Text(user.email)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                HStack {
                    Text("Role")
                    Spacer()
                    HStack(spacing: 4) {
                        if user.role == "admin" {
                            Image(systemName: "shield.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        Text(user.role)
                    }
                    .foregroundColor(.secondary)
                }
                HStack {
                    Text("Phone")
                    Spacer()
                    Text(user.phone ?? "")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("User Details")
            }
            if user.role != "admin" {
                Section {
                    if isLoading {
                        ForEach(0 ..< 4, id: \.self) { _ in
                            ClientListPlaceholder()
                                .listRowBackground(Color.clear)
                                .allowsHitTesting(false)
                        }
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    } else if clients.isEmpty {
                        Text("No clients found")
                            .foregroundColor(.secondary)
                            .font(.callout)
                    } else {
                        ForEach(clients) { client in
                            HStack(spacing: 12) {
                                CompanyLogoImage(
                                    logoUrl: client.companyLogo,
                                    companyName: client.company,
                                    size: 45
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [AppTheme.primary.opacity(0.2), AppTheme.accent.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("\(client.name) \(client.surname ?? "")")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Spacer()
                                    }
                                    if let email = client.email {
                                        HStack(spacing: 4) {
                                            Image(systemName: "envelope")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text(email)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    HStack(spacing: 6) {
                                        if let company = client.company {
                                            HStack(spacing: 4) {
                                                Image(systemName: "building.2")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text(company)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        if client.company != nil && client.company != "" && client.phone != nil && client.phone != "" {
                                            Text("•")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        if let phone = client.phone {
                                            HStack(spacing: 4) {
                                                Image(systemName: "phone")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text(phone)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 1)
                        }
                        if clients.count < totalClients {
                            Button("Load More") {
                                loadMoreClients()
                            }
                            .disabled(isLoading)
                        }
                    }
                } header: {
                    HStack {
                        Text("Clients")
                        Spacer()
                        Text("\(totalClients)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            if user.id != authState.currentUser?.id {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        if isDeleting {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                Spacer()
                            }
                        } else {
                            HStack(spacing: 12) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                Text("Delete User")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(isDeleting)
                } footer: {
                    Text("This will permanently delete the user and all their data including clients, tasks, and files.")
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .background(AppTheme.authBackgroundGradient.ignoresSafeArea())
        .navigationTitle("\(user.name) \(user.surname ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadClients()
        }
        .alert("Delete User", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteUser()
            }
        } message: {
            Text("Are you sure you want to delete \(user.name)? This action cannot be undone.")
        }
    }

    @MainActor
    private func loadClients() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await AdminService.getUserClients(userId: user.id, page: currentPage, size: 20)
            clients = response.items
            totalClients = response.meta.total
        } catch {
            errorMessage = "Failed to load clients: \(error.localizedDescription)"
        }
        isLoading = false
    }

    @MainActor
    private func loadMoreClients() {
        currentPage += 1
        Task {
            do {
                let response = try await AdminService.getUserClients(userId: user.id, page: currentPage, size: 20)
                clients.append(contentsOf: response.items)
            } catch {
                errorMessage = "Failed to load more clients"
            }
        }
    }

    @MainActor
    private func deleteUser() {
        isDeleting = true
        Task {
            do {
                _ = try await AdminService.deleteUser(userId: user.id)
                dismiss()
            } catch {
                errorMessage = "Failed to delete user: \(error.localizedDescription)"
                isDeleting = false
            }
        }
    }
}
