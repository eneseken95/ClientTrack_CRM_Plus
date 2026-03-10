//
//  ClientEmailsView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct ClientEmailsView: View {
    let clientId: Int
    let clientName: String
    @State private var emails: [EmailDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    var body: some View {
        ZStack {
            AppTheme.authBackgroundGradient.ignoresSafeArea()
            Group {
                if isLoading {
                    ProgressView("Loading emails...")
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await loadEmails() }
                        }
                    }
                    .padding()
                } else if emails.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "envelope")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No emails yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(emails) { email in
                        NavigationLink {
                            EmailDetailView(email: email, onDelete: {
                                emails.removeAll { $0.id == email.id }
                            })
                        } label: {
                            EmailRow(email: email)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await deleteEmail(email) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                }
            }
        }
        .navigationTitle("Emails")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadEmails()
        }
    }

    @MainActor
    private func loadEmails() async {
        isLoading = true
        errorMessage = nil
        do {
            emails = try await ClientsService.getClientEmails(clientId: clientId)
        } catch {
            errorMessage = "Failed to load emails: \(error.localizedDescription)"
        }
        isLoading = false
    }

    @MainActor
    private func deleteEmail(_ email: EmailDTO) async {
        do {
            try await ClientsService.deleteEmail(emailId: email.id)
            emails.removeAll { $0.id == email.id }
        } catch {
            errorMessage = "Failed to delete email: \(error.localizedDescription)"
        }
    }
}

struct EmailRow: View {
    let email: EmailDTO
    private var isTaskReminder: Bool {
        email.subject.hasPrefix("Task Reminder:")
    }

    private var taskTitle: String {
        email.subject.replacingOccurrences(of: "Task Reminder: ", with: "")
    }

    var body: some View {
        HStack(spacing: 10) {
            if isTaskReminder {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.pink.opacity(0.15), Color.pink.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.pink)
                }
            } else {
                CompanyLogoImage(
                    logoUrl: email.clientCompanyLogo,
                    companyName: email.clientName ?? email.recipient.components(separatedBy: "@").first ?? email.recipient,
                    size: 34
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [AppTheme.primary.opacity(0.2), AppTheme.accent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
            }
            VStack(alignment: .leading, spacing: 1) {
                if isTaskReminder {
                    Text("Task Reminder")
                        .font(.headline)
                        .lineLimit(1)
                    Text(taskTitle)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                } else {
                    Text(email.recipient)
                        .font(.headline)
                        .lineLimit(1)
                    Text(email.subject)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Text(email.sentAt.toShortDateFormat())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct EmailDetailView: View {
    let email: EmailDTO
    var onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    var body: some View {
        ZStack {
            AppTheme.authBackgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(email.subject)
                            .font(.title2)
                            .fontWeight(.semibold)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("From:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(email.sender)
                                        .font(.subheadline)
                                }
                                HStack {
                                    Text("To:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(email.recipient)
                                        .font(.subheadline)
                                }
                            }
                            Spacer()
                            Text(email.sentAt.toShortDateFormat())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 8)
                    Divider()
                    HTMLTextView(htmlString: email.body)
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                }
                .padding()
            }
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Email")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func deleteEmail() async {
        isDeleting = true
        errorMessage = nil
        do {
            try await ClientsService.deleteEmail(emailId: email.id)
            onDelete()
            dismiss()
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
            isDeleting = false
        }
    }
}
