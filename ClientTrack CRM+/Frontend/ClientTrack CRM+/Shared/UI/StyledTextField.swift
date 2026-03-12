//
//  StyledTextField.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 16.02.2026.
//

import SwiftUI

struct StyledTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var disableAutocorrection: Bool = false
    @State private var isPasswordVisible = false
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 20)
            if isSecure && !isPasswordVisible {
                SecureField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled(disableAutocorrection)
            }
            if isSecure {
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                .fill(Color.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerMedium)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
        .onChange(of: text) { _, newValue in
            if keyboardType == .emailAddress {
                let lowered = newValue.lowercased()
                if lowered != newValue {
                    text = lowered
                }
            }
        }
    }
}
