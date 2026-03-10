//
//  ChangeAvatarView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import PhotosUI
import SwiftUI

struct ChangeAvatarView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: ProfileViewModel
    @State private var pickedItem: PhotosPickerItem?
    @State private var isProcessing: Bool = false
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
            if isProcessing {
                loadingOverlay
            }
        }
        .navigationTitle("Change Avatar")
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
            vm.errorMessage = nil
            vm.info = nil
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await vm.uploadAvatar(
                        authState: authState,
                        jpegData: data
                    )
                } else {
                    vm.errorMessage = "Failed to read image."
                }
                if vm.errorMessage == nil {
                    dismiss()
                } else {
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
                    Text("Updating avatar")
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
            CachedAvatarView(size: 120)
                .environmentObject(authState)
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

    private var placeholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .font(.system(size: 96))
            .foregroundColor(.secondary)
    }
}
