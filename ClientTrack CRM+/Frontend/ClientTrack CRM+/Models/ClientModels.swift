//
//  ClientModels.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

struct PaginatedResponseDTO<T: Decodable>: Decodable {
    let items: [T]
    let meta: PaginationMetaDTO
}

struct PaginationMetaDTO: Decodable {
    let page: Int
    let size: Int
    let total: Int
}

struct ClientDTO: Identifiable, Decodable {
    let id: Int
    let name: String
    let surname: String?
    let email: String?
    let phone: String?
    let company: String?
    let notes: String?
    let source: String?
    let status: String?
    let category: String?
    let industry: String?
    let latitude: String?
    let longitude: String?
    let createdAt: Date?
    let companyLogo: String?

    enum CodingKeys: String, CodingKey {
        case id, name, surname, email, phone, company, notes
        case source, status, category, industry, latitude, longitude
        case createdAt = "created_at"
        case companyLogo = "company_logo"
    }
}

struct ClientCreateDTO: Encodable {
    let name: String
    let surname: String?
    let email: String?
    let phone: String?
    let company: String?
    let notes: String?
    let source: String?
    let status: String?
    let category: String?
    let industry: String?
    let latitude: String?
    let longitude: String?
}

struct ClientPatchDTO: Encodable {
    let name: String?
    let surname: String?
    let email: String?
    let phone: String?
    let company: String?
    let notes: String?
    let source: String?
    let status: String?
    let category: String?
    let industry: String?
    let latitude: String?
    let longitude: String?
}
