//
//  RegisterView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct RegisterView: View {
    @Binding var path: [AuthRoute]
    @StateObject private var vm = RegisterViewModel()
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            AppTheme.authBackgroundGradient
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    Spacer().frame(height: 16)
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 42, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Create Account")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 8)
                    VStack(spacing: 12) {
                        StyledTextField(
                            icon: "person.fill",
                            placeholder: "Name",
                            text: $vm.name
                        )
                        StyledTextField(
                            icon: "person.fill",
                            placeholder: "Surname",
                            text: $vm.surname
                        )
                        StyledTextField(
                            icon: "envelope.fill",
                            placeholder: "Email",
                            text: $vm.email,
                            keyboardType: .emailAddress,
                            autocapitalization: .never,
                            disableAutocorrection: true
                        )
                        StyledTextField(
                            icon: "phone.fill",
                            placeholder: "Phone",
                            text: $vm.phone,
                            keyboardType: .phonePad
                        )
                        StyledTextField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $vm.password,
                            isSecure: true
                        )
                    }
                    if let err = vm.errorMessage {
                        Text(err)
                            .foregroundColor(AppTheme.statusInactive)
                            .font(.caption)
                    }
                    GradientButton(title: "Register", isLoading: vm.isLoading) {
                        Task {
                            let ok = await vm.register()
                            if ok {
                                path.append(.verifyEmail(email: vm.email))
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Register")
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
