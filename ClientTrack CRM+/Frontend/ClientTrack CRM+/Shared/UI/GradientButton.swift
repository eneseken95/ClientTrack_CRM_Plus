//
//  GradientButton.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 16.02.2026.
//

import SwiftUI

struct GradientButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.black)
                        .frame(maxWidth: .infinity)
                } else {
                    HStack(spacing: 10) {
                        if let icon {
                            Image(systemName: icon)
                                .font(.body)
                        }
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .foregroundColor(.black)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                    .strokeBorder(Color.black.opacity(0.8), lineWidth: 1.5)
            )
        }
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}
