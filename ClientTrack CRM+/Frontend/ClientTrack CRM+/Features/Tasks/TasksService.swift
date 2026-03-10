//
//  TasksService.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 22.02.2026.
//

import Foundation

enum TasksService {
    struct CreateTaskPayload: Encodable {
        let title: String
        let description: String?
        let status: String
        let due_date: String?
        let client_id: Int
    }

    static func listAll() async throws -> [TaskDTO] {
        try await APIClient.shared.request(.tasks)
    }

    static func create(title: String, description: String?, status: String, dueDate: Date?, clientId: Int) async throws -> TaskDTO {
        var dueDateStr: String? = nil
        if let dueDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            dueDateStr = formatter.string(from: dueDate)
        }
        let payload = CreateTaskPayload(
            title: title,
            description: description,
            status: status,
            due_date: dueDateStr,
            client_id: clientId
        )
        let data = try JSONCoding.encoder.encode(payload)
        return try await APIClient.shared.request(.createTask, body: data)
    }

    struct UpdateTaskPayload: Encodable {
        let title: String?
        let description: String?
        let status: String?
        let due_date: String?
    }

    static func update(taskId: Int, title: String?, description: String?, status: String?, dueDate: Date?) async throws -> TaskDTO {
        var dueDateStr: String? = nil
        if let dueDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            dueDateStr = formatter.string(from: dueDate)
        }
        let payload = UpdateTaskPayload(
            title: title,
            description: description,
            status: status,
            due_date: dueDateStr
        )
        let data = try JSONCoding.encoder.encode(payload)
        return try await APIClient.shared.request(.patchTask(id: taskId), body: data)
    }

    static func delete(taskId: Int) async throws {
        let _: [String: String] = try await APIClient.shared.request(.deleteTask(id: taskId))
    }
}
