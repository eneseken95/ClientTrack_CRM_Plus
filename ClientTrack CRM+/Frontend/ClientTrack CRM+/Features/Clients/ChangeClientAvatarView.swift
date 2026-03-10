//
//  ChangeClientAvatarView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 22.02.2026.
//

import PhotosUI
import SwiftUI

struct ChangeClientAvatarView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: ClientDetailViewModel
    @State private var pickedItem: PhotosPickerItem?
    @State private var isProcessing: Bool = false
    @State private var localErrorMessage: String?
    var body: some View {
        ZStack {
            Form(content: {
                Section {
                    avatarPreview
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)
                Section {
                    PhotosPicker(
                        selection: $pickedItem,
                        matching: .images
                    ) {
                        HStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(AppTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text("Choose photo")
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 0)
                    }
                    .disabled(isProcessing)
                }
                .listRowBackground(Color.white.opacity(0.1))
            })
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(AppTheme.authBackgroundGradient.ignoresSafeArea())
            .disabled(isProcessing)
            .blur(radius: isProcessing ? 3 : 0)
            if let error = localErrorMessage ?? vm.errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                }
            }
            if isProcessing {
                loadingOverlay
            }
        }
        .navigationTitle("Change Logo")
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
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            isProcessing = true
            localErrorMessage = nil
            vm.errorMessage = nil
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data)
                {
                    await vm.uploadLogo(image: image)
                    if vm.errorMessage == nil {
                        dismiss()
                    } else {
                        isProcessing = false
                    }
                } else {
                    localErrorMessage = "Failed to read image."
                    isProcessing = false
                }
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
                    Text("Updating logo")
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
