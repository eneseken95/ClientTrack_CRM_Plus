//
//  CachedRemoteImage.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 22.02.2026.
//

import SwiftUI

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private init() {
        cache.countLimit = 100
    }

    func get(_ url: String) -> UIImage? {
        cache.object(forKey: url as NSString)
    }

    func set(_ url: String, image: UIImage) {
        cache.setObject(image, forKey: url as NSString)
    }
}

struct CachedRemoteImage: View {
    let url: String?
    let size: CGFloat
    let fallbackIcon: String
    @State private var uiImage: UIImage?
    @State private var isLoading = false
    init(url: String?, size: CGFloat, fallbackIcon: String = "person.crop.circle.fill") {
        self.url = url
        self.size = size
        self.fallbackIcon = fallbackIcon
    }

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if isLoading {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primary.opacity(0.08), AppTheme.accent.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .shimmer()
            } else {
                Image(systemName: fallbackIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear { loadImage() }
    }

    private func loadImage() {
        guard let urlString = url, !urlString.isEmpty else { return }
        if let cached = ImageCache.shared.get(urlString) {
            uiImage = cached
            return
        }
        guard let imageURL = URL(string: urlString) else { return }
        isLoading = true
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                if let downloaded = UIImage(data: data) {
                    ImageCache.shared.set(urlString, image: downloaded)
                    await MainActor.run {
                        uiImage = downloaded
                        isLoading = false
                    }
                } else {
                    await MainActor.run { isLoading = false }
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
}
