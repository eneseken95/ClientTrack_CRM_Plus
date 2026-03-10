//
//  EmailsView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct EmailsView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var vm = EmailsViewModel()
    @State private var showCompose = false
    @State private var showSubscriptionSheet = false
    private var isPremium: Bool {
        authState.currentUser?.subscription_status == "active"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.authBackgroundGradient.ignoresSafeArea()
                Group {
                    if vm.isLoading {
                        List {
                            ForEach(0 ..< 3, id: \.self) { _ in
                                Section {
                                    ForEach(0 ..< 3, id: \.self) { _ in
                                        EmailPlaceholder()
                                            .listRowBackground(Color.clear)
                                            .allowsHitTesting(false)
                                    }
                                } header: {
                                    HStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [AppTheme.primary.opacity(0.08), AppTheme.accent.opacity(0.05)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 20, height: 20)
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.15))
                                            .frame(width: 150, height: 14)
                                    }
                                    .shimmer()
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .scrollIndicators(.hidden)
                    } else if vm.emails.isEmpty {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.subtleGradient)
                                    .frame(width: 110, height: 110)
                                    .blur(radius: 10)
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 52, weight: .light))
                                    .foregroundStyle(AppTheme.primaryGradient)
                            }
                            Text("No Emails")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("No emails found")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        List {
                            ForEach(vm.emails) { email in
                                NavigationLink {
                                    EmailDetailView(email: email, onDelete: {
                                        Task { await vm.removeEmail(email) }
                                    })
                                } label: {
                                    EmailRow(email: email)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task { await vm.removeEmail(email) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .padding(.top, 0)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .scrollIndicators(.hidden)
                    }
                }
                .blur(radius: isPremium ? 0 : 8)
                .disabled(!isPremium)
                if !isPremium {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                        Text("Standard Email Integration")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                        Text("Send professional emails to your clients directly from the app by upgrading your plan.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                        Button {
                            showSubscriptionSheet = true
                        } label: {
                            Text("Upgrade Plan")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(AppTheme.primary)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 30)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                }
            }
            .background(AppTheme.authBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Emails")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if isPremium {
                            showCompose = true
                        } else {
                            showSubscriptionSheet = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.primaryGradient)
                    }
                }
            }
            .sheet(isPresented: $showCompose) {
                ComposeEmailView { _ in
                    Task { await vm.loadAllEmails() }
                }
            }
            .task {
                if isPremium {
                    await vm.loadAllEmails()
                }
            }
            .refreshable {
                if isPremium {
                    await vm.loadAllEmails()
                }
            }
            .sheet(isPresented: $showSubscriptionSheet) {
                NavigationStack {
                    SubscriptionView(isPresentedAsSheet: true)
                }
            }
        }
    }
}

@MainActor
final class EmailsViewModel: ObservableObject {
    @Published var emails: [EmailDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    func loadAllEmails() async {
        isLoading = true
        errorMessage = nil
        do {
            emails = try await EmailsService.listAll()
        } catch {
            errorMessage = "Failed to load emails: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func removeEmail(_ email: EmailDTO) async {
        do {
            try await EmailsService.deleteEmail(id: email.id)
            DispatchQueue.main.async {
                self.emails.removeAll { $0.id == email.id }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to delete email: \(error.localizedDescription)"
            }
        }
    }
}
