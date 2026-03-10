//
//  LoginView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var vm = LoginViewModel()
    @EnvironmentObject var authState: AuthState
    @State private var path: [AuthRoute] = []
    @State private var appeared = false
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AppTheme.authBackgroundGradient
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 80)
                        VStack(spacing: 12) {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .shadow(color: .white.opacity(0.15), radius: 12, x: 0, y: 0)
                            Text("ClientTrack CRM+")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Manage your clients effortlessly")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.bottom, 8)
                        VStack(spacing: 14) {
                            StyledTextField(
                                icon: "envelope.fill",
                                placeholder: "Email",
                                text: $vm.email,
                                keyboardType: .emailAddress,
                                autocapitalization: .never,
                                disableAutocorrection: true
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
                                .padding(.horizontal, 4)
                        }
                        GradientButton(title: "Login", isLoading: vm.isLoading) {
                            Task {
                                let user = await vm.login()
                                if let user { authState.setLoggedIn(user: user) }
                            }
                        }
                        HStack {
                            Button {
                                path.append(.register)
                            } label: {
                                Text("Create account")
                                    .font(.callout)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Button {
                                path.append(.forgotPassword)
                            } label: {
                                Text("Forgot password?")
                                    .font(.callout)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 28)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5)) { appeared = true }
            }
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .register:
                    RegisterView(path: $path)
                case let .verifyEmail(email):
                    VerifyEmailView(email: email, path: $path)
                case .forgotPassword:
                    ForgotPasswordView(path: $path)
                case let .resetPassword(email):
                    ResetPasswordView(email: email, path: $path)
                }
            }
        }
    }
}
