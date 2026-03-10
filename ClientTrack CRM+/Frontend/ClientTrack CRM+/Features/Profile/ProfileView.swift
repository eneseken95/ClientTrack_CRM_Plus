//
//  ProfileView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import PhotosUI
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var vm = ProfileViewModel()
    @State private var showEdit = false
    @State private var showChangeEmail = false
    @State private var showDelete = false
    enum Route: Hashable {
        case changeAvatar
        case deleteAvatar
    }

    private var personPlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 56, height: 56)
            .foregroundColor(.secondary)
    }

    var body: some View {
        profileContent
            .id(authState.avatarVersion)
            .sheet(isPresented: $showEdit) {
                EditProfileView(vm: vm)
                    .environmentObject(authState)
            }
            .sheet(isPresented: $showChangeEmail) {
                ChangeEmailView(vm: vm)
                    .environmentObject(authState)
            }
            .sheet(isPresented: $showDelete) {
                DeleteAccountView(vm: vm)
                    .environmentObject(authState)
            }
            .onChange(of: authState.status) { _, newStatus in
                handleAuthStatusChange(newStatus)
            }
            .onChange(of: vm.shouldLogout) { _, v in
                handleLogoutChange(v)
            }
    }

    private var profileContent: some View {
        Group {
            if let u = authState.currentUser {
                profileList(for: u)
            } else {
                loadingView
            }
        }
    }

    private func profileList(for user: UserOutDTO) -> some View {
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
                        avatarView(urlString: user.avatar_url)
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
                NavigationLink {
                    ChangeAvatarView(vm: vm)
                        .environmentObject(authState)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Change avatar")
                            .foregroundColor(.white)
                    }
                }
                .disabled(vm.isBusy)
                NavigationLink {
                    DeleteAvatarView(vm: vm)
                        .environmentObject(authState)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Delete avatar")
                            .foregroundColor(.white)
                    }
                }
                .disabled(user.avatar_url == nil || vm.isBusy)
            } header: {
                Text("Avatar")
                    .foregroundColor(.gray)
            }
            Section {
                profileRow(icon: "envelope.fill", color: .pink, title: "Email", value: user.email)
                profileRow(icon: "person.fill", color: .blue, title: "Name", value: user.name)
                profileRow(icon: "person.fill", color: .teal, title: "Surname", value: user.surname)
                profileRow(icon: "shield.fill", color: .orange, title: "Role", value: user.role)
                profileRow(icon: "phone.fill", color: .green, title: "Phone", value: user.phone)
            } header: {
                Text("Account")
            }
            Section {
                Button {
                    showEdit = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Edit profile")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
                Button {
                    showChangeEmail = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Change email")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
                NavigationLink {
                    SubscriptionView()
                        .environmentObject(authState)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.55, green: 0.25, blue: 0.85),
                                        Color(red: 0.25, green: 0.47, blue: 0.95),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Subscription")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                Button(role: .destructive) {
                    showDelete = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Delete account")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
            } header: {
                Text("Actions")
                    .foregroundColor(.gray)
            }
            if user.role == "admin" {
                Section {
                    NavigationLink {
                        AdminPanelView()
                            .environmentObject(authState)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text("Admin Panel")
                                .foregroundColor(.white)
                        }
                    }
                } header: {
                    Text("Administration")
                }
            }
            Section {
                Button(role: .destructive) {
                    authState.logout()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.forward")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Log out")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .font(.body)
                    .fontWeight(.medium)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .background(AppTheme.authBackgroundGradient.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: authState.status) {
            await loadProfileIfNeeded()
        }
        .task(id: authState.status) {
            await loadProfileIfNeeded()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(AppTheme.primary)
            Text("Loading profile…")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Profile")
        .task(id: authState.status) {
            await loadProfileIfNeeded()
        }
    }

    private func handleAuthStatusChange(_ newStatus: AuthStatus) {
        if newStatus == .unauthenticated {
            showEdit = false
            showChangeEmail = false
            showDelete = false
            vm.hasLoadedOnce = false
        }
    }

    private func handleLogoutChange(_ shouldLogout: Bool) {
        if shouldLogout {
            showEdit = false
            showChangeEmail = false
            showDelete = false
            authState.logout()
            vm.shouldLogout = false
            vm.hasLoadedOnce = false
        }
    }

    @MainActor
    private func loadProfileIfNeeded() async {
        if vm.didUpdateAvatar {
            vm.didUpdateAvatar = false
            return
        }
        guard authState.status == .authenticated else { return }
        guard vm.hasLoadedOnce == false else { return }
        vm.hasLoadedOnce = true
        await vm.refreshMe(authState: authState)
    }

    private func profileRow(icon: String, color: Color, title: String, value: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text(title)
            Spacer()
            Text((value?.isEmpty == false) ? value! : "—")
                .foregroundColor(.secondary)
        }
    }

    private func avatarView(urlString _: String?) -> some View {
        CachedAvatarView(size: 120)
            .environmentObject(authState)
    }
}
