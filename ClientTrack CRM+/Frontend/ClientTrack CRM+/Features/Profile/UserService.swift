//
//  UserService.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

struct EmptyResponse: Decodable {}

struct SimpleMessageResponse: Decodable {
    let message: String
}

import Foundation

enum UsersService {
    static func me() async throws -> UserOutDTO {
        try await APIClient.shared.request(.me)
    }

    static func updateMe(payload: UpdateUserRequestDTO) async throws -> UserOutDTO {
        let body = try JSONCoding.encoder.encode(payload)
        return try await APIClient.shared.request(.updateMe, body: body)
    }

    static func uploadAvatar(jpegData: Data) async throws -> UserOutDTO {
        var form = MultipartFormData()
        form.addFile(fieldName: "file", fileName: "avatar.jpg", mimeType: "image/jpeg", fileData: jpegData)
        form.finalize()
        return try await APIClient.shared.requestRaw(
            .uploadAvatar,
            body: form.body,
            contentType: form.contentTypeHeader
        )
    }

    static func deleteAvatar() async throws -> UserOutDTO {
        try await APIClient.shared.request(.deleteAvatar)
    }

    static func requestEmailChange(newEmail: String) async throws {
        let body = try JSONCoding.encoder.encode(
            ChangeEmailRequestDTO(new_email: newEmail)
        )
        _ = try await APIClient.shared.request(
            .changeEmail,
            body: body
        ) as EmptyResponse
    }

    static func verifyEmailChange(otp: String) async throws -> UserOutDTO {
        let body = try JSONCoding.encoder.encode(OTPRequestDTO(otp: otp))
        return try await APIClient.shared.request(.verifyEmailChange, body: body)
    }

    static func deleteRequest() async throws -> String {
        let response: SimpleMessageResponse = try await APIClient.shared.request(.deleteRequest)
        return response.message
    }

    static func verifyDelete(otp: String) async throws -> String {
        let body = try JSONCoding.encoder.encode(OTPRequestDTO(otp: otp))
        let response: SimpleMessageResponse = try await APIClient.shared.request(.verifyDelete, body: body)
        return response.message
    }
}
