//
//  CachedAvatarView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct CachedAvatarView: View {
    @EnvironmentObject var authState: AuthState
    let size: CGFloat
    private var personPlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundColor(.secondary)
    }

    var body: some View {
        Group {
            if let cachedImage = authState.cachedAvatarImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .id(authState.avatarVersion)
            } else if let urlString = authState.currentUser?.avatar_url,
                      !urlString.isEmpty,
                      let url = URL(string: urlString)
            {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: size, height: size)
                            .shimmer()
                    case let .success(img):
                        img.resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure:
                        personPlaceholder
                    @unknown default:
                        EmptyView()
                    }
                }
                .id("\(authState.avatarVersion)-\(urlString)")
            } else {
                personPlaceholder
            }
        }
    }
}
