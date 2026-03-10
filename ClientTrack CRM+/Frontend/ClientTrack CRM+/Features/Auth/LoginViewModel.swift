//
//  LoginViewModel.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    func login() async -> UserOutDTO? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let res = try await AuthService.login(email: email, password: password)
            TokenStore.shared.set(access: res.tokens.access_token, refresh: res.tokens.refresh_token)
            return res.user
        } catch {
            errorMessage = "Email or Password is wrong or missing"
            return nil
        }
    }
}
