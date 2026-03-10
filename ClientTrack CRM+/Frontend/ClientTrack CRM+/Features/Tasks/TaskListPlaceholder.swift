//
//  TaskListPlaceholder.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 22.02.2026.
//

import SwiftUI

struct TaskListPlaceholder: View {
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primary.opacity(0.08), AppTheme.accent.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 180, height: 16)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 220, height: 12)
                HStack(spacing: 8) {
                    Capsule()
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 60, height: 18)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 80, height: 12)
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .shimmer()
    }
}
