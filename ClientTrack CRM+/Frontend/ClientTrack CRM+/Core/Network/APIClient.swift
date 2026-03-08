//
//  APIClient.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

enum APIError: Error {
    case invalidResponse
    case http(Int, Data)
    case unauthorized
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

    func request<T: Decodable>(
        _ endpoint: Endpoint,
        body: Data? = nil,
        contentType: String = "application/json"
    ) async throws -> T {
        do {
            return try await perform(endpoint, body: body, contentType: contentType)
        } catch APIError.unauthorized {
            guard endpoint.requiresAuth else { throw APIError.unauthorized }
            try await refreshTokens()
            return try await perform(endpoint, body: body, contentType: contentType)
        }
    }

    private func perform<T: Decodable>(
        _ endpoint: Endpoint,
        body: Data?,
        contentType: String
    ) async throws -> T {
        var req = URLRequest(url: endpoint.url())
        req.httpMethod = endpoint.method
        req.httpBody = body
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        if endpoint.requiresAuth, let token = TokenStore.shared.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.invalidResponse }
        if http.statusCode == 401 { throw APIError.unauthorized }
        guard (200 ... 299).contains(http.statusCode) else { throw APIError.http(http.statusCode, data) }
        return try JSONCoding.decoder.decode(T.self, from: data)
    }

    private func refreshTokens() async throws {
        guard let refresh = TokenStore.shared.refreshToken else { throw APIError.unauthorized }
        let payload = RefreshRequestDTO(refresh_token: refresh)
        let body = try JSONCoding.encoder.encode(payload)
        let tokens: TokenPairDTO = try await perform(.refresh, body: body, contentType: "application/json")
        TokenStore.shared.set(access: tokens.access_token, refresh: tokens.refresh_token)
    }
}

extension APIClient {
    func requestRaw<T: Decodable>(
        _ endpoint: Endpoint,
        body: Data?,
        contentType: String
    ) async throws -> T {
        do {
            return try await performRaw(endpoint, body: body, contentType: contentType)
        } catch APIError.unauthorized {
            guard endpoint.requiresAuth else { throw APIError.unauthorized }
            try await refreshTokens()
            return try await performRaw(endpoint, body: body, contentType: contentType)
        }
    }

    private func performRaw<T: Decodable>(
        _ endpoint: Endpoint,
        body: Data?,
        contentType: String
    ) async throws -> T {
        var req = URLRequest(url: endpoint.url())
        req.httpMethod = endpoint.method
        req.httpBody = body
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        if endpoint.requiresAuth,
           let token = TokenStore.shared.accessToken
        {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if http.statusCode == 401 {
            throw APIError.unauthorized
        }
        guard (200 ... 299).contains(http.statusCode) else {
            throw APIError.http(http.statusCode, data)
        }
        return try JSONCoding.decoder.decode(T.self, from: data)
    }
}
