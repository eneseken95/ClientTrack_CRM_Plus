//
//  SearchService.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

enum SearchService {
    static func searchClients(query: String) async throws -> [ClientDTO] {
        guard !query.isEmpty else {
            return []
        }
        return try await APIClient.shared.request(.searchClients(q: query))
    }
}
