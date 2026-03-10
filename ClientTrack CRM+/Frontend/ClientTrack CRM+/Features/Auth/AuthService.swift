//
//  AuthService.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

enum AuthService {
    static func login(email: String, password: String) async throws -> LoginResponseDTO {
        let payload = LoginRequestDTO(email: email, password: password)
        let body = try JSONCoding.encoder.encode(payload)
        return try await APIClient.shared.request(.login, body: body)
    }

    static func register(payload: RegisterRequestDTO) async throws -> UserOutDTO {
        let body = try JSONCoding.encoder.encode(payload)
        return try await APIClient.shared.request(.register, body: body)
    }

    static func verifyEmail(payload: VerifyEmailRequestDTO) async throws -> MessageDTO {
        let body = try JSONCoding.encoder.encode(payload)
        return try await APIClient.shared.request(.verifyEmail, body: body)
    }

    static func resendOTP(payload: ResendOTPRequestDTO) async throws -> MessageDTO {
        let body = try JSONCoding.encoder.encode(payload)
        return try await APIClient.shared.request(.resendOTP, body: body)
    }

    static func forgotPassword(payload: ForgotPasswordRequestDTO) async throws -> MessageDTO {
        let body = try JSONCoding.encoder.encode(payload)
        return try await APIClient.shared.request(.forgotPassword, body: body)
    }

    static func resetPassword(payload: ResetPasswordRequestDTO) async throws -> MessageDTO {
        let body = try JSONCoding.encoder.encode(payload)
        return try await APIClient.shared.request(.resetPassword, body: body)
    }
}
