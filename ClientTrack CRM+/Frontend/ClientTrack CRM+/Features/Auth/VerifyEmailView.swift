//
//  VerifyEmailView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct VerifyEmailView: View {
    let email: String
    @Binding var path: [AuthRoute]
    @StateObject private var vm = VerifyEmailViewModel()
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            AppTheme.authBackgroundGradient
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer().frame(height: 24)
                VStack(spacing: 8) {
                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Verify Email")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(email)
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 8)
                StyledTextField(
                    icon: "number",
                    placeholder: "OTP Code",
                    text: $vm.code,
                    keyboardType: .numberPad
                )
                if let err = vm.errorMessage {
                    Text(err)
                        .foregroundColor(AppTheme.statusInactive)
                        .font(.caption)
                }
                GradientButton(title: "Verify", isLoading: vm.isLoading) {
                    Task {
                        let ok = await vm.verify(email: email)
                        if ok {
                            path.removeAll()
                        }
                    }
                }
                Button {
                    Task { await vm.resend(email: email) }
                } label: {
                    Text("Resend OTP")
                        .font(.callout)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .navigationTitle("OTP")
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
