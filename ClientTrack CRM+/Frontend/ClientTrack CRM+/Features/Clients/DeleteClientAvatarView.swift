//
//  DeleteClientAvatarView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 22.02.2026.
//

import SwiftUI

struct DeleteClientAvatarView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: ClientDetailViewModel
    @State private var isProcessing = false
    var body: some View {
        ZStack {
            Form {
                Section {
                    avatarPreview
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)
                Section {
                    Button(role: .destructive) {
                        confirmDelete()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text("Delete Logo")
                        }
                        .foregroundColor(.white)
                    }
                    .disabled(isProcessing)
                }
                .listRowBackground(Color.white.opacity(0.1))
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(AppTheme.authBackgroundGradient.ignoresSafeArea())
            .disabled(isProcessing)
            .blur(radius: isProcessing ? 3 : 0)
            if isProcessing {
                loadingOverlay
            }
        }
        .navigationTitle("Delete Logo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    private func confirmDelete() {
        isProcessing = true
        vm.errorMessage = nil
        Task {
            await vm.deleteLogo()
            if vm.errorMessage == nil {
                dismiss()
            } else {
                isProcessing = false
            }
        }
    }

    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 14) {
                    ProgressView()
                        .scaleEffect(1.4)
                    Text("Deleting logo")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(28)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
            }
    }

    private var avatarPreview: some View {
        ZStack {
            Circle()
                .fill(AppTheme.subtleGradient)
                .frame(width: 110, height: 110)
                .blur(radius: 20)
                .frame(width: 150, height: 150)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            CompanyLogoImage(
                logoUrl: vm.client.companyLogo,
                companyName: vm.client.company ?? vm.client.name,
                size: 120
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [AppTheme.primary.opacity(0.3), AppTheme.accent.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 124, height: 124)
            )
        }
    }
}
