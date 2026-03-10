//
//  TasksView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct TasksView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var vm = TasksViewModel()
    @State private var showCreate = false
    @State private var selectedTask: TaskDTO?
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.authBackgroundGradient.ignoresSafeArea()
                Group {
                    if vm.isLoading {
                        List {
                            ForEach(0 ..< 6, id: \.self) { _ in
                                TaskListPlaceholder()
                                    .listRowBackground(Color.clear)
                                    .allowsHitTesting(false)
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .scrollIndicators(.hidden)
                    } else if vm.tasks.isEmpty {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.subtleGradient)
                                    .frame(width: 110, height: 110)
                                    .blur(radius: 10)
                                Image(systemName: "checklist")
                                    .font(.system(size: 52, weight: .light))
                                    .foregroundStyle(AppTheme.primaryGradient)
                            }
                            Text("No Tasks")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Tap + to create your first task")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        List {
                            ForEach(vm.tasks) { task in
                                Button {
                                    selectedTask = task
                                } label: {
                                    TaskRow(task: task)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task { await vm.delete(task) }
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
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreate = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.primaryGradient)
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                TaskCreateView { newTask in
                    vm.tasks.insert(newTask, at: 0)
                }
            }
            .sheet(item: $selectedTask) { task in
                TaskEditView(task: task) { updatedTask in
                    vm.replace(updatedTask)
                }
            }
            .task {
                await vm.loadTasks()
            }
            .refreshable {
                await vm.loadTasks()
            }
        }
    }
}

struct TaskRow: View {
    let task: TaskDTO

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                if let desc = task.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                HStack(alignment: .center, spacing: 6) {
                    if let dueDate = task.due_date {
                        Text(dueDate.toShortDateFormat())
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    if let clientName = task.client_name {
                        if task.due_date != nil {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.4))
                        }
                        HStack(spacing: 4) {
                            CompanyLogoImage(
                                logoUrl: task.client_logo,
                                companyName: clientName,
                                size: 14
                            )
                            .clipShape(Circle())
                            Text(clientName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.trailing, -2)
        }
        .padding(.vertical, 3)
    }

    private var statusIcon: String {
        switch task.status {
        case "completed": return "checkmark.circle.fill"
        case "in_progress": return "clock.fill"
        default: return "circle"
        }
    }

    private var statusLabel: String {
        switch task.status {
        case "completed": return "Completed"
        case "in_progress": return "In Progress"
        case "pending": return "Pending"
        default: return task.status.capitalized
        }
    }

    private var statusColor: Color {
        switch task.status {
        case "completed": return AppTheme.statusActive
        case "in_progress": return AppTheme.statusPending
        default: return .gray
        }
    }
}

@MainActor
final class TasksViewModel: ObservableObject {
    @Published var tasks: [TaskDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    func loadTasks() async {
        isLoading = true
        do {
            tasks = try await TasksService.listAll()
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func replace(_ task: TaskDTO) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
        }
    }

    func delete(_ task: TaskDTO) async {
        do {
            try await TasksService.delete(taskId: task.id)
            tasks.removeAll { $0.id == task.id }
        } catch {
            errorMessage = "Failed to delete task"
        }
    }
}
