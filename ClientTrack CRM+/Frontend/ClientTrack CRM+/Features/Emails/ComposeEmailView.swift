//
//  ComposeEmailView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 21.02.2026.
//

import SwiftUI

struct ComposeEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authState: AuthState
    @StateObject private var vm = ComposeEmailViewModel()
    @State private var showClientPicker = false
    @State private var showSubscriptionPaywall = false
    @State private var showSubscriptionSheet = false
    var onSent: ((EmailDTO) -> Void)?
    
    private var canUseAIPolish: Bool {
        guard let user = authState.currentUser, user.subscription_status == "active" else { return false }
        if let planId = user.subscription_plan_id, planId.contains("basic") {
            return false
        }
        return true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.authBackgroundGradient
                    .ignoresSafeArea()
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("To")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button {
                                    showClientPicker = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                        Text("Select Client")
                                    }
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(AppTheme.primary)
                                }
                            }
                            StyledTextField(
                                icon: "envelope.fill",
                                placeholder: "Recipient email",
                                text: $vm.toEmail,
                                keyboardType: .emailAddress,
                                autocapitalization: .never,
                                disableAutocorrection: true
                            )
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Subject")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            StyledTextField(
                                icon: "text.alignleft",
                                placeholder: "Email subject",
                                text: $vm.subject
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                                    .fill(Color.purple.opacity(0.15))
                                    .opacity(vm.isPolishing ? 1 : 0)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                                    .strokeBorder(Color.purple.opacity(0.6), lineWidth: 1.5)
                                    .opacity(vm.isPolishing ? 1 : 0)
                            )
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Message")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextEditor(text: $vm.body)
                                .scrollContentBackground(.hidden)
                                .scrollIndicators(.hidden)
                                .foregroundColor(.white)
                                .frame(minHeight: 200)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                                        .fill(vm.isPolishing ? Color.purple.opacity(0.15) : Color.white.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                                        .strokeBorder(vm.isPolishing ? Color.purple.opacity(0.6) : Color.white.opacity(0.15), lineWidth: vm.isPolishing ? 1.5 : 1)
                                )
                        }
                        if let err = vm.errorMessage {
                            Text(err)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        Button {
                            if canUseAIPolish {
                                Task { await vm.aiPolish() }
                            } else {
                                showSubscriptionPaywall = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if !canUseAIPolish {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 16))
                                }
                                if vm.isPolishing {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                } else if canUseAIPolish {
                                    Image(systemName: "sparkles")
                                }
                                Text(vm.isPolishing ? "AI is polishing..." : "AI Polish")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                                    .fill(Color.purple.opacity(0.3))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                                    .strokeBorder(Color.purple.opacity(0.5), lineWidth: 1)
                            )
                            .opacity(canUseAIPolish ? 1.0 : 0.6)
                        }
                        .disabled(vm.subject.isEmpty && vm.body.isEmpty || vm.isPolishing)
                        .opacity((vm.subject.isEmpty && vm.body.isEmpty) ? 0.4 : 1.0)
                        GradientButton(title: "Send Email", isLoading: vm.isSending) {
                            Task {
                                let email = await vm.send()
                                if let email {
                                    onSent?(email)
                                    dismiss()
                                }
                            }
                        }
                        .disabled(vm.toEmail.isEmpty || vm.subject.isEmpty || vm.body.isEmpty)
                        .opacity((vm.toEmail.isEmpty || vm.subject.isEmpty || vm.body.isEmpty) ? 0.4 : 1.0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Compose Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert("Subscription Required", isPresented: $showSubscriptionPaywall) {
                Button("Upgrade Plan") {
                    showSubscriptionSheet = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You need a subscription to use this feature. Please upgrade your plan to unlock AI Polish.")
            }
            .sheet(isPresented: $showSubscriptionSheet) {
                NavigationStack {
                    SubscriptionView(isPresentedAsSheet: true)
                }
            }
        }
        .task {
            await vm.loadClients()
        }
        .sheet(isPresented: $showClientPicker) {
            NavigationStack {
                Group {
                    if vm.isLoadingClients {
                        ProgressView("Loading clients...")
                    } else if vm.clients.isEmpty {
                        Text("No clients found.")
                            .foregroundColor(.secondary)
                    } else {
                        List {
                            ForEach(vm.clients) { client in
                                if let email = client.email, !email.isEmpty {
                                    Button {
                                        vm.toEmail = email
                                        vm.selectedClientId = client.id
                                        showClientPicker = false
                                    } label: {
                                        HStack(spacing: 12) {
                                            CompanyLogoImage(
                                                logoUrl: client.companyLogo,
                                                companyName: client.company,
                                                size: 40
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
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("\(client.name) \(client.surname ?? "")")
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                                if let company = client.company {
                                                    Text(company)
                                                        .font(.caption)
                                                        .foregroundColor(.primary.opacity(0.8))
                                                }
                                                Text(email)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .listRowBackground(Color.white.opacity(0.1))
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .scrollIndicators(.hidden)
                        .background(AppTheme.authBackgroundGradient.ignoresSafeArea())
                    }
                }
                .navigationTitle("Select Client")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") { showClientPicker = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

@MainActor
final class ComposeEmailViewModel: ObservableObject {
    @Published var toEmail = ""
    @Published var selectedClientId: Int?
    @Published var subject = ""
    @Published var body = ""
    @Published var isSending = false
    @Published var isPolishing = false
    @Published var errorMessage: String?
    @Published var clients: [ClientDTO] = []
    @Published var isLoadingClients = false
    func loadClients() async {
        guard clients.isEmpty else { return }
        isLoadingClients = true
        do {
            let response = try await ClientsService.fetch(page: 1, size: 100)
            clients = response.items
        } catch {}
        isLoadingClients = false
    }

    func aiPolish() async {
        isPolishing = true
        errorMessage = nil
        defer { isPolishing = false }
        do {
            let result = try await EmailsService.aiPolish(
                subject: subject.isEmpty ? "(draft)" : subject,
                body: body.isEmpty ? "(draft)" : body
            )
            subject = result.subject
            body = result.body
        } catch {
            errorMessage = "AI polish failed: \(error.localizedDescription)"
        }
    }

    func send() async -> EmailDTO? {
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        
        var finalClientId = selectedClientId
        if finalClientId == nil {
            if let matchedClient = clients.first(where: { $0.email?.lowercased() == toEmail.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }) {
                finalClientId = matchedClient.id
            }
        }
        
        do {
            return try await EmailsService.sendEmail(
                clientId: finalClientId,
                toEmail: toEmail,
                subject: subject,
                body: body
            )
        } catch let APIError.http(statusCode, data) {
            let detail = String(data: data, encoding: .utf8) ?? "Unknown"
            errorMessage = "Server error (\(statusCode)): \(detail)"
            return nil
        } catch {
            errorMessage = "Failed to send: \(error.localizedDescription)"
            return nil
        }
    }
}
