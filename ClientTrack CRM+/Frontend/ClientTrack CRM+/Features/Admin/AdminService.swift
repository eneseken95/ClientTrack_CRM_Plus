//
//  AdminService.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

enum AdminService {
    static func listAllUsers() async throws -> [UserOutDTO] {
        try await APIClient.shared.request(.adminListUsers)
    }

    static func getUserClients(userId: Int, page: Int = 1, size: Int = 20) async throws -> PaginatedResponseDTO<ClientDTO> {
        try await APIClient.shared.request(.adminGetUserClients(userId: userId, page: page, size: size))
    }

    static func deleteUser(userId: Int) async throws -> SimpleMessageResponse {
        try await APIClient.shared.request(.adminDeleteUser(userId: userId))
    }
}
