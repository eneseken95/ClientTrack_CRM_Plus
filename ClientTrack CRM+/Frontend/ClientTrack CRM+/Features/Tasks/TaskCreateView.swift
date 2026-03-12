//
//  TaskCreateView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 22.02.2026.
//

import SwiftUI

struct TaskCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = TaskCreateViewModel()
    @State private var showClientPicker = false
    @State private var selectedClientName = ""
    let onCreated: (TaskDTO) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Info") {
                    TextField("Title", text: $vm.title)
                    TextField("Description", text: $vm.description)
                }
                Section("Status") {
                    Picker("Status", selection: $vm.status) {
                        Text("Pending").tag("pending")
                        Text("In Progress").tag("in_progress")
                        Text("Completed").tag("completed")
                    }
                }
                Section("Due Date") {
                    Toggle("Set Due Date", isOn: $vm.hasDueDate)
                        .tint(.green)
                    if vm.hasDueDate {
                        DatePicker("Due Date", selection: $vm.dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                Section("Client") {
                    Button {
                        showClientPicker = true
                    } label: {
                        HStack {
                            Text("Client")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(selectedClientName.isEmpty ? "Select a client" : selectedClientName)
                                .foregroundColor(selectedClientName.isEmpty ? .secondary : .primary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                if let error = vm.errorMessage {
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
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            if let task = await vm.create() {
                                onCreated(task)
                                dismiss()
                            }
                        }
                    } label: {
                        if vm.isLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(vm.title.isEmpty || vm.selectedClientId == 0 || vm.isLoading)
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
                                    Button {
                                        vm.selectedClientId = client.id
                                        selectedClientName = "\(client.name) \(client.surname ?? "")"
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
                                                if let email = client.email, !email.isEmpty {
                                                    Text(email)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                    .listRowBackground(Color.white.opacity(0.1))
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
}

@MainActor
final class TaskCreateViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var status = "pending"
    @Published var hasDueDate = false
    @Published var dueDate = Date()
    @Published var selectedClientId = 0
    @Published var clients: [ClientDTO] = []
    @Published var isLoadingClients = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    func loadClients() async {
        isLoadingClients = true
        do {
            let response = try await ClientsService.fetch(page: 1, size: 100)
            clients = response.items
        } catch {
            errorMessage = "Failed to load clients"
        }
        isLoadingClients = false
    }

    func create() async -> TaskDTO? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            return try await TasksService.create(
                title: title,
                description: description.isEmpty ? nil : description,
                status: status,
                dueDate: hasDueDate ? dueDate : nil,
                clientId: selectedClientId
            )
        } catch {
            errorMessage = "Failed to create task: \(error.localizedDescription)"
            return nil
        }
    }
}
