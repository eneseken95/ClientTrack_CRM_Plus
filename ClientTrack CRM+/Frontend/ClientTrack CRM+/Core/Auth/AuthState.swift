//
//  AuthState.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation
import UIKit

@MainActor
final class AuthState: ObservableObject {
    @Published var status: AuthStatus = .checkingSession
    @Published var currentUser: UserOutDTO?
    @Published var avatarVersion: Int = 0
    @Published var profileViewResetID = UUID()
    @Published var cachedAvatarImage: UIImage?
    init() {
        Task {
            await restoreSession()
        }
    }

    func restoreSession() async {
        guard TokenStore.shared.refreshToken != nil else {
            status = .unauthenticated
            return
        }
        do {
            let user = try await UsersService.me()
            currentUser = user
            status = .authenticated
            cachedAvatarImage = AvatarCacheManager.shared.loadAvatar(forUserId: user.id)
        } catch {
            logout()
        }
    }

    func setLoggedIn(user: UserOutDTO) {
        currentUser = user
        status = .authenticated
        cachedAvatarImage = AvatarCacheManager.shared.loadAvatar(forUserId: user.id)
    }

    func logout() {
        cachedAvatarImage = nil
        TokenStore.shared.clear()
        currentUser = nil
        status = .unauthenticated
    }
}
