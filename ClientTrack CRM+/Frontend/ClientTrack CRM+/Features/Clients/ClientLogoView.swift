//
//  ClientLogoView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import PhotosUI
import SwiftUI

struct ClientLogoView: View {
    let clientId: Int
    let clientName: String
    @State private var logoUrl: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var showDeleteConfirmation = false
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    if let logoUrl = logoUrl, let url = URL(string: logoUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 200, height: 200)
                                    .shimmer()
                            case let .success(image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 200)
                                    .clipShape(Circle())
                            case .failure:
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 200, height: 200)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 80))
                                            .foregroundColor(.secondary)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else if !isLoading && !isUploading {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 200, height: 200)
                            .overlay(
                                VStack(spacing: 16) {
                                    Image(systemName: "building.2")
                                        .font(.system(size: 80))
                                        .foregroundColor(.secondary)
                                    Text("No logo uploaded")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                    if isUploading {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 200, height: 200)
                            .shimmer()
                    }
                }
                if isLoading {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 200)
                        .shimmer()
                }
                VStack(spacing: 12) {
                    Button {
                        showImagePicker = true
                    } label: {
                        Label(logoUrl == nil ? "Upload Logo" : "Change Logo", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isUploading)
                    if logoUrl != nil {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Logo", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isUploading)
                    }
                }
                .padding(.horizontal)
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Company Logo")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .alert("Delete Logo?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteLogo() }
            }
        } message: {
            Text("This will permanently delete the company logo.")
        }
        .task {
            await loadLogo()
        }
        .onChange(of: selectedImage) { _, newValue in
            if let image = newValue {
                Task { await uploadLogo(image: image) }
            }
        }
    }

    @MainActor
    private func loadLogo() async {
        isLoading = true
        errorMessage = nil
        do {
            logoUrl = try await ClientsService.getCompanyLogo(clientId: clientId)
        } catch {
            errorMessage = "Failed to load logo: \(error.localizedDescription)"
        }
        isLoading = false
    }

    @MainActor
    private func uploadLogo(image: UIImage) async {
        isUploading = true
        errorMessage = nil
        do {
            logoUrl = try await ClientsService.uploadCompanyLogo(clientId: clientId, image: image)
            selectedImage = nil
            NotificationCenter.default.post(
                name: .clientLogoUpdated,
                object: clientId
            )
        } catch {
            errorMessage = "Failed to upload logo: \(error.localizedDescription)"
        }
        isUploading = false
    }

    @MainActor
    private func deleteLogo() async {
        isUploading = true
        errorMessage = nil
        do {
            try await ClientsService.deleteCompanyLogo(clientId: clientId)
            logoUrl = nil
            NotificationCenter.default.post(
                name: .clientLogoUpdated,
                object: clientId
            )
        } catch {
            errorMessage = "Failed to delete logo: \(error.localizedDescription)"
        }
        isUploading = false
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_: UIImagePickerController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
