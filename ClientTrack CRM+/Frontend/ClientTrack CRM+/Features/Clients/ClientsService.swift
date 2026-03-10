//
//  ClientsService.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation
import UIKit

enum ClientsService {
    static func fetch(page: Int, size: Int) async throws -> PaginatedResponseDTO<ClientDTO> {
        try await APIClient.shared.request(.clients(page: page, size: size))
    }

    static func create(_ payload: ClientCreateDTO) async throws -> ClientDTO {
        let body = try JSONCoding.encoder.encode(payload)
        return try await APIClient.shared.request(.createClient, body: body)
    }

    static func patch(id: Int, payload: ClientPatchDTO) async throws -> ClientDTO {
        let body = try JSONCoding.encoder.encode(payload)
        return try await APIClient.shared.request(.patchClient(id: id), body: body)
    }

    static func delete(id: Int) async throws {
        struct EmptyResponse: Codable {}
        let _: EmptyResponse? = try? await APIClient.shared.request(.deleteClient(id: id))
    }

    static func getClientEmails(clientId: Int) async throws -> [EmailDTO] {
        try await APIClient.shared.request(.clientEmails(id: clientId))
    }

    static func uploadCompanyLogo(clientId: Int, image: UIImage) async throws -> String {
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ClientsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])
        }

        struct LogoResponse: Codable {
            let status: String
            let path: String
            let signedUrl: String

            enum CodingKeys: String, CodingKey {
                case status
                case path
                case signedUrl = "signed_url"
            }
        }
        var form = MultipartFormData()
        form.addFile(fieldName: "file", fileName: "logo.jpg", mimeType: "image/jpeg", fileData: jpegData)
        form.finalize()
        let response: LogoResponse = try await APIClient.shared.requestRaw(
            .uploadCompanyLogo(id: clientId),
            body: form.body,
            contentType: form.contentTypeHeader
        )
        return response.signedUrl
    }

    static func getCompanyLogo(clientId: Int) async throws -> String? {
        struct LogoResponse: Codable {
            let logo: String?
        }
        let response: LogoResponse = try await APIClient.shared.request(.getCompanyLogo(id: clientId))
        return response.logo
    }

    static func deleteCompanyLogo(clientId: Int) async throws {
        struct StatusResponse: Codable {
            let status: String
        }
        let _: StatusResponse = try await APIClient.shared.request(.deleteCompanyLogo(id: clientId))
    }

    static func uploadAttachment(clientId: Int, data: Data, fileName: String) async throws -> String {
        struct AttachmentResponse: Codable {
            let status: String
            let signedUrl: String
            let name: String

            enum CodingKeys: String, CodingKey {
                case status
                case signedUrl = "signed_url"
                case name
            }
        }
        let mimeType = fileName.hasSuffix(".pdf") ? "application/pdf" : "application/octet-stream"
        var form = MultipartFormData()
        form.addFile(fieldName: "file", fileName: fileName, mimeType: mimeType, fileData: data)
        form.finalize()
        let response: AttachmentResponse = try await APIClient.shared.requestRaw(
            .uploadAttachment(clientId: clientId),
            body: form.body,
            contentType: form.contentTypeHeader
        )
        return response.signedUrl
    }

    static func getAttachments(clientId: Int) async throws -> [AttachmentDTO] {
        try await APIClient.shared.request(.listAttachments(clientId: clientId))
    }

    static func deleteAttachment(clientId: Int, path: String) async throws {
        struct StatusResponse: Codable {
            let status: String
        }
        let request = DeleteAttachmentRequest(path: path)
        let body = try JSONEncoder().encode(request)
        let _: StatusResponse = try await APIClient.shared.request(.deleteAttachment(clientId: clientId), body: body)
    }

    static func deleteEmail(emailId: Int) async throws {
        let _: MessageDTO = try await APIClient.shared.request(.deleteEmail(id: emailId))
    }
}
