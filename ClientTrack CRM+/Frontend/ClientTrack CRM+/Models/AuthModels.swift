//
//  AuthModels.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

struct UserOutDTO: Decodable, Identifiable {
    let id: Int
    let name: String
    let surname: String?
    let email: String
    let role: String
    let phone: String?
    let avatar_url: String?
    let subscription_status: String?
    let subscription_plan_id: String?
    let current_period_end: String?
}

struct TokenPairDTO: Decodable {
    let access_token: String
    let refresh_token: String
    let token_type: String?
}

struct LoginResponseDTO: Decodable {
    let user: UserOutDTO
    let tokens: TokenPairDTO
}

struct LoginRequestDTO: Encodable {
    let email: String
    let password: String
}

struct RefreshRequestDTO: Encodable {
    let refresh_token: String
}
