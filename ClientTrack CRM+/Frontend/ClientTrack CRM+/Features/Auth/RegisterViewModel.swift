//
//  RegisterViewModel.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

@MainActor
final class RegisterViewModel: ObservableObject {
    @Published var name = ""
    @Published var surname = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    func register() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let payload = RegisterRequestDTO(name: name, surname: surname, email: email, phone: phone, password: password)
            _ = try await AuthService.register(payload: payload)
            return true
        } catch {
            errorMessage = "Register failed."
            return false
        }
    }
}
