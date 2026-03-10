//
//  ProfileViewModel.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var isBusy = false
    @Published var errorMessage: String?
    @Published var info: String?
    @Published var shouldLogout = false
    @Published var hasLoadedOnce = false
    @Published var didUpdateAvatar: Bool = false
    func refreshMe(authState: AuthState) async {
        do {
            let me = try await UsersService.me()
            authState.currentUser = me
            hasLoadedOnce = true
        } catch {
            errorMessage = "Failed to load profile."
        }
    }

    func updateMe(authState: AuthState, name: String, surname: String, phone: String) async {
        isBusy = true; errorMessage = nil; info = nil
        defer { isBusy = false }
        do {
            let updated = try await UsersService.updateMe(
                payload: UpdateUserRequestDTO(name: name, surname: surname, phone: phone.nonEmpty)
            )
            authState.currentUser = updated
            didUpdateAvatar = true
        } catch {
            errorMessage = "Update failed."
        }
    }

    func uploadAvatar(authState: AuthState, jpegData: Data) async {
        isBusy = true
        errorMessage = nil
        info = nil
        defer { isBusy = false }
        if let image = UIImage(data: jpegData) {
            authState.cachedAvatarImage = image
            AvatarCacheManager.shared.saveAvatar(image, forUserId: authState.currentUser!.id)
        }
        do {
            let updatedUser = try await UsersService.uploadAvatar(jpegData: jpegData)
            authState.currentUser = updatedUser
            didUpdateAvatar = true
            authState.avatarVersion += 1
            authState.profileViewResetID = UUID()
        } catch {
            if case let APIError.http(statusCode, data) = error {
                if let errorText = String(data: data, encoding: .utf8) {
                    errorMessage = "Upload failed (\(statusCode)): \(errorText)"
                } else {
                    errorMessage = "Upload failed with status \(statusCode)"
                }
            } else {
                errorMessage = "Avatar upload failed."
            }
        }
    }

    func deleteAvatar(authState: AuthState) async {
        isBusy = true
        errorMessage = nil
        info = nil
        defer { isBusy = false }
        do {
            let updatedUser = try await UsersService.deleteAvatar()
            authState.cachedAvatarImage = nil
            AvatarCacheManager.shared.deleteAvatar(forUserId: updatedUser.id)
            authState.avatarVersion += 1
            authState.currentUser = updatedUser
            authState.objectWillChange.send()
            authState.profileViewResetID = UUID()
            didUpdateAvatar = true
        } catch {
            errorMessage = "Avatar delete failed."
        }
    }

    func requestEmailChange(newEmail: String) async -> Bool {
        isBusy = true
        errorMessage = nil
        info = nil
        defer { isBusy = false }
        do {
            try await UsersService.requestEmailChange(newEmail: newEmail)
            return true
        } catch {
            errorMessage = "Email change request failed."
            return false
        }
    }

    func verifyEmailChange(authState: AuthState, otp: String) async -> Bool {
        isBusy = true; errorMessage = nil; info = nil
        defer { isBusy = false }
        do {
            let updatedUser = try await UsersService.verifyEmailChange(otp: otp)
            authState.currentUser = updatedUser
            return true
        } catch {
            errorMessage = "OTP verify failed."
            return false
        }
    }

    func deleteRequest() async -> Bool {
        isBusy = true; errorMessage = nil; info = nil
        defer { isBusy = false }
        do {
            _ = try await UsersService.deleteRequest()
            return true
        } catch {
            errorMessage = "Delete request failed."
            return false
        }
    }

    func verifyDelete(otp: String) async -> Bool {
        isBusy = true; errorMessage = nil; info = nil
        defer { isBusy = false }
        do {
            _ = try await UsersService.verifyDelete(otp: otp)
            return true
        } catch {
            errorMessage = "OTP verification failed."
            return false
        }
    }
}
