//
//  DeleteAccountView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct DeleteAccountView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: ProfileViewModel
    @State private var otp = ""
    @State private var step: Int = 1
    @FocusState private var isOtpFocused: Bool
    var body: some View {
        NavigationStack {
            Form(content: {
                if step == 1 {
                    if authState.currentUser?.role == "admin" {
                        Section {
                            Text("Admin accounts cannot be deleted for security reasons.")
                                .font(.callout)
                                .foregroundColor(.red)
                        }
                    } else {
                        Section(footer: Group {
                            if let err = vm.errorMessage, step == 1 {
                                Text(err)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }) {
                            Text("This will send an OTP to confirm account deletion.")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        Button(role: .destructive) {
                            Task {
                                let ok = await vm.deleteRequest()
                                if ok {
                                    await MainActor.run {
                                        step = 2
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                Text("Send OTP")
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.isBusy)
                        .opacity(vm.isBusy ? 0.4 : 1.0)
                    }
                } else {
                    Section(header: Text("OTP"), footer: Group {
                        if let err = vm.errorMessage, err.contains("OTP") {
                            Text("Incorrect OTP entered")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }) {
                        TextField("otp", text: $otp)
                            .keyboardType(.numberPad)
                            .focused($isOtpFocused)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        isOtpFocused = false
                                    }
                                }
                            }
                    }
                    Button(role: .destructive) {
                        Task {
                            let ok = await vm.verifyDelete(otp: otp)
                            if ok {
                                if let userId = authState.currentUser?.id {
                                    AvatarCacheManager.shared.deleteAvatar(forUserId: userId)
                                }
                                authState.logout()
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text("Confirm Delete")
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isBusy || otp.isEmpty)
                    .opacity((vm.isBusy || otp.isEmpty) ? 0.4 : 1.0)
                }
            })
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(AppTheme.authBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Delete Account")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
