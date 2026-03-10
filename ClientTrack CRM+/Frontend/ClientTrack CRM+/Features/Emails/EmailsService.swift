//
//  EmailsService.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 21.02.2026.
//

import Foundation

enum EmailsService {
    struct SendEmailPayload: Encodable {
        let client_id: Int?
        let to_email: String
        let subject: String
        let body: String

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(client_id, forKey: .client_id)
            try container.encode(to_email, forKey: .to_email)
            try container.encode(subject, forKey: .subject)
            try container.encode(body, forKey: .body)
        }

        enum CodingKeys: String, CodingKey {
            case client_id, to_email, subject, body
        }
    }

    static func sendEmail(clientId: Int?, toEmail: String, subject: String, body: String) async throws -> EmailDTO {
        let payload = SendEmailPayload(client_id: clientId, to_email: toEmail, subject: subject, body: body)
        let data = try JSONCoding.encoder.encode(payload)
        return try await APIClient.shared.request(.sendEmail, body: data)
    }

    static func listAll() async throws -> [EmailDTO] {
        try await APIClient.shared.request(.listEmails)
    }

    static func deleteEmail(id: Int) async throws {
        let _: [String: String]? = try? await APIClient.shared.request(.deleteEmail(id: id))
    }

    struct AiPolishPayload: Encodable {
        let subject: String
        let body: String
    }

    struct AiPolishResponse: Decodable {
        let subject: String
        let body: String
    }

    static func aiPolish(subject: String, body: String) async throws -> AiPolishResponse {
        let payload = AiPolishPayload(subject: subject, body: body)
        let data = try JSONCoding.encoder.encode(payload)
        return try await APIClient.shared.request(.aiPolish, body: data)
    }
}
