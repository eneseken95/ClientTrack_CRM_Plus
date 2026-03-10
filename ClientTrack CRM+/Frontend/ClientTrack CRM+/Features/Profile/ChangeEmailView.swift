//
//  ChangeEmailView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct ChangeEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authState: AuthState
    @ObservedObject var vm: ProfileViewModel
    @State private var newEmail = ""
    @State private var otp = ""
    @State private var otpSent = false
    @State private var showSuccessAlert = false
    var body: some View {
        NavigationStack {
            Form {
                Section("New Email") {
                    TextField("New Email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(otpSent)
                }
                if !otpSent {
                    Section {
                        Button {
                            sendOTP()
                        } label: {
                            if vm.isBusy {
                                ProgressView()
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                        .background(.green)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    Text("Send OTP")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(vm.isBusy || newEmail.isEmpty)
                        .opacity((vm.isBusy || newEmail.isEmpty) ? 0.4 : 1.0)
                    }
                }
                if otpSent {
                    Section {
                        Text("OTP has been sent to:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(newEmail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Section(header: Text("OTP"), footer: Group {
                        if let err = vm.errorMessage, err.contains("OTP") {
                            Text("Incorrect OTP entered")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }) {
                        TextField("OTP code", text: $otp)
                            .keyboardType(.numberPad)
                    }
                    Section {
                        Button {
                            verifyOTP()
                        } label: {
                            if vm.isBusy {
                                ProgressView()
                            } else {
                                Text("Verify & Log out")
                            }
                        }
                        .disabled(vm.isBusy || otp.isEmpty)
                        .opacity((vm.isBusy || otp.isEmpty) ? 0.4 : 1.0)
                    }
                }
                if let err = vm.errorMessage, !err.contains("OTP") {
                    Section {
                        Text(err)
                            .foregroundColor(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(AppTheme.authBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Change Email")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Email Verified", isPresented: $showSuccessAlert) {
                Button("Log out") {
                    dismiss()
                    authState.logout()
                    vm.shouldLogout = false
                }
            } message: {
                Text("Your email has been successfully changed. Please log in again.")
            }
        }
    }

    private func sendOTP() {
        let email = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, !vm.isBusy else { return }
        Task {
            let success = await vm.requestEmailChange(newEmail: email)
            if success {
                await MainActor.run {
                    otpSent = true
                }
            }
        }
    }

    private func verifyOTP() {
        let cleanOtp = otp.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanOtp.isEmpty else { return }
        Task {
            let success = await vm.verifyEmailChange(authState: authState, otp: cleanOtp)
            if success {
                await MainActor.run {
                    showSuccessAlert = true
                }
            }
        }
    }
}
