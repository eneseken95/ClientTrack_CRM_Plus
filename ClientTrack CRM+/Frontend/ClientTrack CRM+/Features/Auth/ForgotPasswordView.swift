//
//  ForgotPasswordView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Binding var path: [AuthRoute]
    @StateObject private var vm = ForgotPasswordViewModel()
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            AppTheme.authBackgroundGradient
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer().frame(height: 24)
                VStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Forgot Password")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Enter your email to receive an OTP")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 8)
                StyledTextField(
                    icon: "envelope.fill",
                    placeholder: "Email",
                    text: $vm.email,
                    keyboardType: .emailAddress,
                    autocapitalization: .never,
                    disableAutocorrection: true
                )
                if let err = vm.errorMessage {
                    Text(err)
                        .foregroundColor(AppTheme.statusInactive)
                        .font(.caption)
                }
                GradientButton(title: "Send OTP", isLoading: vm.isLoading) {
                    Task {
                        let ok = await vm.send()
                        if ok {
                            path.append(.resetPassword(email: vm.email))
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .navigationTitle("Forgot")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                }
            }
        }
    }
}
