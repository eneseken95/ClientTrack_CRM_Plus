//
//  TokenStore.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

final class TokenStore {
    static let shared = TokenStore()
    private init() {}
    private let accessKey = "access_token"
    private let refreshKey = "refresh_token"
    var accessToken: String? {
        get { KeychainService.read(accessKey) }
        set {
            if let value = newValue {
                KeychainService.save(value, for: accessKey)
            } else {
                KeychainService.delete(accessKey)
            }
        }
    }

    var refreshToken: String? {
        get { KeychainService.read(refreshKey) }
        set {
            if let value = newValue {
                KeychainService.save(value, for: refreshKey)
            } else {
                KeychainService.delete(refreshKey)
            }
        }
    }

    func set(access: String, refresh: String) {
        accessToken = access
        refreshToken = refresh
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
    }
}
