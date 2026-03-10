//
//  CompanyLogoImage.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct CompanyLogoImage: View {
    let logoUrl: String?
    let companyName: String?
    let size: CGFloat
    init(logoUrl: String?, companyName: String?, size: CGFloat = 40) {
        self.logoUrl = logoUrl
        self.companyName = companyName
        self.size = size
    }

    var body: some View {
        Group {
            if let urlString = logoUrl, !urlString.isEmpty {
                CachedRemoteImage(url: urlString, size: size, fallbackIcon: "person.crop.circle.fill")
            } else {
                fallbackIcon
            }
        }
    }

    private var fallbackIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.primary.opacity(0.15),
                            AppTheme.accent.opacity(0.10),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            if let name = companyName?.first {
                Text(String(name).uppercased())
                    .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.primary)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(AppTheme.primary)
            }
        }
    }
}
