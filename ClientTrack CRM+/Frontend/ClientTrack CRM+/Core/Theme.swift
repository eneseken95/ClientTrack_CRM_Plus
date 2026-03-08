//
//  Theme.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 16.02.2026.
//

import SwiftUI

enum AppTheme {
    static let primary = Color.white
    static let primaryDark = Color(white: 0.85)
    static let accent = Color(red: 0.16, green: 0.71, blue: 0.96)
    static let accentSecondary = Color.white
    static let cardBackground = Color(.systemBackground)
    static let surfaceSecondary = Color(.secondarySystemBackground)
    static let surfaceTertiary = Color(.tertiarySystemBackground)
    static let statusActive = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let statusInactive = Color(red: 0.93, green: 0.26, blue: 0.28)
    static let statusPending = Color(red: 1.0, green: 0.62, blue: 0.04)
    static let statusLead = Color(red: 0.25, green: 0.47, blue: 0.95)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    static let primaryGradient = LinearGradient(
        colors: [primary, accentSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let authBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.06, green: 0.06, blue: 0.08),
            Color(red: 0.08, green: 0.08, blue: 0.10),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let splashGradient = LinearGradient(
        colors: [
            Color(red: 0.06, green: 0.06, blue: 0.08),
            Color(red: 0.08, green: 0.08, blue: 0.10),
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    static let subtleGradient = LinearGradient(
        colors: [primary.opacity(0.08), accent.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cornerSmall: CGFloat = 8
    static let cornerMedium: CGFloat = 12
    static let cornerLarge: CGFloat = 16
    static let cornerXL: CGFloat = 20

    static func cardShadow() -> some ViewModifier {
        CardShadow()
    }

    static func statusColor(for status: String) -> Color {
        let lowercased = status.lowercased()
        switch lowercased {
        case "active", "open":
            return statusActive
        case "inactive", "closed":
            return statusInactive
        case "pending":
            return statusPending
        case "lead":
            return statusLead
        default:
            return .gray
        }
    }
}

struct CardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

struct GlassMorphism: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium))
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func cardShadow() -> some View {
        modifier(CardShadow())
    }

    func glassMorphism() -> some View {
        modifier(GlassMorphism())
    }
}
