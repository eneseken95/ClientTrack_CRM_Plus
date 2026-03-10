//
//  ClientCreateViewModel.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

@MainActor
final class ClientCreateViewModel: ObservableObject {
    @Published var name = ""
    @Published var surname = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var company = ""
    @Published var notes = ""
    @Published var source = ""
    @Published var status = ""
    @Published var category = ""
    @Published var industry = ""
    @Published var latitude = ""
    @Published var longitude = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    func create() async -> ClientDTO? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let payload = ClientCreateDTO(
            name: name,
            surname: surname,
            email: email,
            phone: phone,
            company: company,
            notes: notes,
            source: source,
            status: status,
            category: category,
            industry: industry,
            latitude: latitude.isEmpty ? nil : latitude,
            longitude: longitude.isEmpty ? nil : longitude
        )
        do {
            return try await ClientsService.create(payload)
        } catch {
            errorMessage = "Client could not be created."
            return nil
        }
    }
}
