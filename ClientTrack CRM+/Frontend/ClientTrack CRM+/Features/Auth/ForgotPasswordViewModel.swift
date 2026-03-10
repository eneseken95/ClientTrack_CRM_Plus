//
//  ForgotPasswordViewModel.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

@MainActor
final class ForgotPasswordViewModel: ObservableObject {
    @Published var email = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    func send() async -> Bool {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        defer { isLoading = false }
        do {
            let payload = ForgotPasswordRequestDTO(email: email)
            let msg = try await AuthService.forgotPassword(payload: payload)
            infoMessage = msg.message
            return true
        } catch {
            errorMessage = "Failed to send OTP."
            return false
        }
    }
}
