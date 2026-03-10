//
//  ClientDetailViewModel.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation
import UIKit

@MainActor
class ClientDetailViewModel: ObservableObject {
    @Published var client: ClientDTO
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var success: String?
    init(client: ClientDTO) {
        self.client = client
    }

    func updateClient(
        name: String,
        surname: String,
        email: String,
        phone: String,
        company: String,
        notes: String,
        source: String,
        status: String,
        category: String,
        industry: String,
        latitude: String?,
        longitude: String?
    ) async {
        isSaving = true
        errorMessage = nil
        success = nil
        do {
            let payload = ClientPatchDTO(
                name: name,
                surname: surname.isEmpty ? nil : surname,
                email: email.isEmpty ? nil : email,
                phone: phone.isEmpty ? nil : phone,
                company: company.isEmpty ? nil : company,
                notes: notes.isEmpty ? nil : notes,
                source: source.isEmpty ? nil : source,
                status: status.isEmpty ? nil : status,
                category: category.isEmpty ? nil : category,
                industry: industry.isEmpty ? nil : industry,
                latitude: latitude,
                longitude: longitude
            )
            let updated = try await ClientsService.patch(id: client.id, payload: payload)
            client = updated
            success = "Client updated successfully"
        } catch {
            errorMessage = "Failed to update: \(error.localizedDescription)"
        }
        isSaving = false
    }

    func deleteClient() async -> Bool {
        isSaving = true
        errorMessage = nil
        do {
            try await ClientsService.delete(id: client.id)
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .clientDeleted,
                    object: client.id
                )
            }
            return true
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }

    func refreshClient() async {
        do {
            let response = try await ClientsService.fetch(page: 1, size: 100)
            if let updatedClient = response.items.first(where: { $0.id == client.id }) {
                await MainActor.run {
                    self.client = updatedClient
                }
            }
        } catch {}
    }

    func uploadLogo(image: UIImage) async {
        isSaving = true
        errorMessage = nil
        success = nil
        do {
            let logoUrl = try await ClientsService.uploadCompanyLogo(clientId: client.id, image: image)
            await MainActor.run {
                self.client = ClientDTO(
                    id: self.client.id,
                    name: self.client.name,
                    surname: self.client.surname,
                    email: self.client.email,
                    phone: self.client.phone,
                    company: self.client.company,
                    notes: self.client.notes,
                    source: self.client.source,
                    status: self.client.status,
                    category: self.client.category,
                    industry: self.client.industry,
                    latitude: self.client.latitude,
                    longitude: self.client.longitude,
                    createdAt: self.client.createdAt,
                    companyLogo: logoUrl
                )
                self.success = "Logo updated successfully"
                NotificationCenter.default.post(
                    name: .clientLogoUpdated,
                    object: client.id
                )
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to upload logo: \(error.localizedDescription)"
            }
        }
        isSaving = false
    }

    func deleteLogo() async {
        isSaving = true
        errorMessage = nil
        success = nil
        do {
            try await ClientsService.deleteCompanyLogo(clientId: client.id)
            await MainActor.run {
                self.client = ClientDTO(
                    id: self.client.id,
                    name: self.client.name,
                    surname: self.client.surname,
                    email: self.client.email,
                    phone: self.client.phone,
                    company: self.client.company,
                    notes: self.client.notes,
                    source: self.client.source,
                    status: self.client.status,
                    category: self.client.category,
                    industry: self.client.industry,
                    latitude: self.client.latitude,
                    longitude: self.client.longitude,
                    createdAt: self.client.createdAt,
                    companyLogo: nil
                )
                self.success = "Logo deleted successfully"
                NotificationCenter.default.post(
                    name: .clientLogoUpdated,
                    object: client.id
                )
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete logo: \(error.localizedDescription)"
            }
        }
        isSaving = false
    }
}
