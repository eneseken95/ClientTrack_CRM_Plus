//
//  AdminUserListPlaceholder.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 22.02.2026.
//

import SwiftUI

struct AdminUserListPlaceholder: View {
    var body: some View {
        List {
            ForEach(0 ..< 8, id: \.self) { _ in
                HStack(spacing: 12) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primary.opacity(0.08), AppTheme.accent.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 180, height: 16)
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.12))
                                .frame(width: 80, height: 12)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.12))
                                .frame(width: 100, height: 12)
                        }
                        Capsule()
                            .fill(Color.gray.opacity(0.12))
                            .frame(width: 60, height: 18)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
                .shimmer()
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .allowsHitTesting(false)
    }
}
