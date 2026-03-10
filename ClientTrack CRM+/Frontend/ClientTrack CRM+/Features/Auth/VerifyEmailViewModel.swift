//
//  VerifyEmailViewModel.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

@MainActor
final class VerifyEmailViewModel: ObservableObject {
    @Published var code = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    func verify(email: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        defer { isLoading = false }
        do {
            let payload = VerifyEmailRequestDTO(email: email, otp: code)
            let msg = try await AuthService.verifyEmail(payload: payload)
            infoMessage = msg.message
            return true
        } catch {
            errorMessage = "OTP verify failed."
            return false
        }
    }

    func resend(email: String) async {
        errorMessage = nil
        infoMessage = nil
        do {
            let payload = ResendOTPRequestDTO(email: email)
            let msg = try await AuthService.resendOTP(payload: payload)
            infoMessage = msg.message
        } catch {
            errorMessage = "Resend failed."
        }
    }
}
