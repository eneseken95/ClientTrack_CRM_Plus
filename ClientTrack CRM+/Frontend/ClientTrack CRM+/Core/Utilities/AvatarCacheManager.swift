//
//  AvatarCacheManager.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import UIKit

final class AvatarCacheManager {
    static let shared = AvatarCacheManager()
    private init() {}
    private let fileManager = FileManager.default

    private func cacheURL(forUserId userId: Int) -> URL? {
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let avatarDir = cacheDir.appendingPathComponent("AvatarCache")
        try? fileManager.createDirectory(at: avatarDir, withIntermediateDirectories: true)
        return avatarDir.appendingPathComponent("avatar_\(userId).jpg")
    }

    func saveAvatar(_ image: UIImage, forUserId userId: Int) {
        guard let url = cacheURL(forUserId: userId),
              let jpegData = image.jpegData(compressionQuality: 0.8)
        else {
            return
        }
        do {
            try jpegData.write(to: url)
        } catch {}
    }

    func loadAvatar(forUserId userId: Int) -> UIImage? {
        guard let url = cacheURL(forUserId: userId),
              fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data)
        else {
            return nil
        }
        return image
    }

    func deleteAvatar(forUserId userId: Int) {
        guard let url = cacheURL(forUserId: userId),
              fileManager.fileExists(atPath: url.path)
        else {
            return
        }
        do {
            try fileManager.removeItem(at: url)
        } catch {}
    }

    func clearAllAvatars() {
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }
        let avatarDir = cacheDir.appendingPathComponent("AvatarCache")
        try? fileManager.removeItem(at: avatarDir)
    }
}
