//
//  ResetPasswordView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct ResetPasswordView: View {
    let email: String
    @Binding var path: [AuthRoute]
    @StateObject private var vm = ResetPasswordViewModel()
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            AppTheme.authBackgroundGradient
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer().frame(height: 24)
                VStack(spacing: 8) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(email)
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 8)
                VStack(spacing: 12) {
                    StyledTextField(
                        icon: "number",
                        placeholder: "OTP Code",
                        text: $vm.code,
                        keyboardType: .numberPad
                    )
                    StyledTextField(
                        icon: "lock.fill",
                        placeholder: "New Password",
                        text: $vm.newPassword,
                        isSecure: true
                    )
                }
                if let err = vm.errorMessage {
                    Text(err)
                        .foregroundColor(AppTheme.statusInactive)
                        .font(.caption)
                }
                GradientButton(title: "Reset", isLoading: vm.isLoading) {
                    Task {
                        let ok = await vm.reset(email: email)
                        if ok {
                            path.removeAll()
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .navigationTitle("Reset")
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
