//
//  TaskEditView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 22.02.2026.
//

import SwiftUI

struct TaskEditView: View {
    @Environment(\.dismiss) private var dismiss
    let task: TaskDTO
    let onUpdated: (TaskDTO) -> Void
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var status: String = "pending"
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = .init()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var originalDueDate: Date?
    private var isDirty: Bool {
        let titleChanged = title != task.title
        let descriptionChanged = description != (task.description ?? "")
        let statusChanged = status != task.status
        let hasDateChanged = hasDueDate != (task.due_date != nil)
        var dateChanged = false
        if hasDueDate, let original = originalDueDate {
            dateChanged = abs(dueDate.timeIntervalSince(original)) > 1
        }
        return titleChanged || descriptionChanged || statusChanged || hasDateChanged || dateChanged
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Info") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                }
                Section("Related Client") {
                    HStack(spacing: 12) {
                        CompanyLogoImage(
                            logoUrl: task.client_logo,
                            companyName: task.client_company ?? task.client_name,
                            size: 42
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
                        .shadow(color: AppTheme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                if let company = task.client_company {
                                    Text(company)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                } else {
                                    Text(task.client_name ?? "No Company")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                                if let status = task.client_status {
                                    Text(status)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(AppTheme.statusColor(for: status).opacity(0.12))
                                        )
                                        .foregroundColor(AppTheme.statusColor(for: status))
                                }
                            }
                            HStack(spacing: 6) {
                                if let category = task.client_category {
                                    HStack(spacing: 4) {
                                        Image(systemName: "tag.fill")
                                            .font(.system(size: 9))
                                        Text(category)
                                            .font(.caption)
                                    }
                                    .foregroundColor(AppTheme.textSecondary)
                                }
                                if task.client_category != nil && task.client_industry != nil {
                                    Text("·")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textTertiary)
                                }
                                if let industry = task.client_industry {
                                    HStack(spacing: 4) {
                                        Image(systemName: "building.2.fill")
                                            .font(.system(size: 9))
                                        Text(industry)
                                            .font(.caption)
                                    }
                                    .foregroundColor(AppTheme.textSecondary)
                                }
                                if task.client_category == nil && task.client_industry == nil, let email = task.client_email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.white.opacity(0.05))
                }
                Section("Status") {
                    Picker("Status", selection: $status) {
                        Text("Pending").tag("pending")
                        Text("In Progress").tag("in_progress")
                        Text("Completed").tag("completed")
                    }
                }
                Section("Due Date") {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                        .tint(.green)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(
                AppTheme.authBackgroundGradient
                    .ignoresSafeArea()
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            )
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(title.isEmpty || isLoading || !isDirty)
                }
            }
            .onAppear {
                title = task.title
                description = task.description ?? ""
                status = task.status
                if let dueDateStr = task.due_date {
                    let isoFormatter = ISO8601DateFormatter()
                    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let date = isoFormatter.date(from: dueDateStr) {
                        dueDate = date
                        originalDueDate = date
                        hasDueDate = true
                    } else {
                        isoFormatter.formatOptions = [.withInternetDateTime]
                        if let date = isoFormatter.date(from: dueDateStr) {
                            dueDate = date
                            originalDueDate = date
                            hasDueDate = true
                        }
                    }
                }
            }
        }
    }

    @MainActor
    private func save() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let updated = try await TasksService.update(
                taskId: task.id,
                title: title,
                description: description.isEmpty ? nil : description,
                status: status,
                dueDate: hasDueDate ? dueDate : nil
            )
            onUpdated(updated)
            dismiss()
        } catch {
            errorMessage = "Failed to update: \(error.localizedDescription)"
        }
    }
}
