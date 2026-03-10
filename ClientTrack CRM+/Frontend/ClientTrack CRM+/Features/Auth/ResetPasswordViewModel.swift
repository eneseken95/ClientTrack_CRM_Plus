//
//  ResetPasswordViewModel.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

@MainActor
final class ResetPasswordViewModel: ObservableObject {
    @Published var code = ""
    @Published var newPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    func reset(email: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        defer { isLoading = false }
        do {
            let payload = ResetPasswordRequestDTO(email: email, otp: code, new_password: newPassword)
            let msg = try await AuthService.resetPassword(payload: payload)
            infoMessage = msg.message
            return true
        } catch {
            errorMessage = "Reset failed."
            return false
        }
    }
}
