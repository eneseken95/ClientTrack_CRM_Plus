//
//  VerifyEmailChangeView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct VerifyEmailChangeView: View {
    let vm: ProfileViewModel
    let newEmail: String
    @EnvironmentObject var authState: AuthState
    @State private var otp = ""
    @State private var showSuccessAlert = false
    @FocusState private var isOtpFocused: Bool
    var body: some View {
        Form {
            Section("OTP Verification") {
                Text("OTP sent to:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(newEmail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("OTP", text: $otp)
                    .keyboardType(.numberPad)
                    .focused($isOtpFocused)
            }
            Button {
                verify()
            } label: {
                if vm.isBusy {
                    ProgressView()
                } else {
                    Text("Verify")
                }
            }
            .buttonStyle(.plain)
            .disabled(vm.isBusy || otp.isEmpty)
            if let err = vm.errorMessage {
                Text(err)
                    .foregroundColor(.red)
            }
        }
        .scrollIndicators(.hidden)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isOtpFocused = false
                }
            }
        }
        .navigationTitle("Verify Email")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Email Verified", isPresented: $showSuccessAlert) {
            Button("Log out") {
                vm.shouldLogout = true
            }
        } message: {
            Text("Your email has been successfully changed. Please log in again.")
        }
    }

    private func verify() {
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
