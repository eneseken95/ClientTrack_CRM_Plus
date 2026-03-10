//
//  ClientAttachmentsView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ClientAttachmentsView: View {
    let clientId: Int
    let clientName: String
    @State private var attachments: [AttachmentDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var attachmentToDelete: AttachmentDTO?
    @State private var selectedAttachment: AttachmentDTO?
    var body: some View {
        ZStack {
            AppTheme.authBackgroundGradient.ignoresSafeArea()
            Group {
                if isLoading && attachments.isEmpty {
                    ProgressView("Loading Attachments")
                } else if attachments.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        Text("No photos yet")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                        Button {
                            showImagePicker = true
                        } label: {
                            Label("Upload Photo", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundColor(.black)
                        .tint(AppTheme.primary)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: 8) {
                            ForEach(attachments) { attachment in
                                PhotoThumbnail(attachment: attachment) {
                                    selectedAttachment = attachment
                                } onDelete: {
                                    attachmentToDelete = attachment
                                }
                            }
                        }
                        .padding()
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showImagePicker = true
                            } label: {
                                Image(systemName: "plus")
                            }
                            .disabled(isUploading)
                        }
                    }
                }
            }
        }
        .navigationTitle("Photos")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { _, newValue in
            if let image = newValue {
                Task { await uploadPhoto(image: image) }
            }
        }
        .fullScreenCover(item: $selectedAttachment) { attachment in
            FullScreenPhotoView(attachment: attachment) {
                selectedAttachment = nil
            }
        }
        .alert("Delete Photo?", isPresented: Binding(
            get: { attachmentToDelete != nil },
            set: { if !$0 { attachmentToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                attachmentToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let attachment = attachmentToDelete {
                    Task { await deleteAttachment(attachment) }
                }
            }
        } message: {
            Text("This will permanently delete this photo.")
        }
        .disabled(isUploading)
        .blur(radius: isUploading ? 3 : 0)
        .overlay {
            if isUploading {
                loadingOverlay
            }
        }
        .task {
            await loadAttachments()
        }
    }

    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 14) {
                    ProgressView()
                        .scaleEffect(1.4)
                        .tint(.white)
                    Text("Uploading photo")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(28)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
            }
    }

    @MainActor
    private func loadAttachments() async {
        isLoading = true
        errorMessage = nil
        do {
            attachments = try await ClientsService.getAttachments(clientId: clientId)
        } catch {
            errorMessage = "Failed to load attachments: \(error.localizedDescription)"
        }
        isLoading = false
    }

    @MainActor
    private func uploadPhoto(image: UIImage) async {
        isUploading = true
        errorMessage = nil
        do {
            guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
                errorMessage = "Failed to convert image"
                isUploading = false
                return
            }
            let fileName = "photo_\(Int(Date().timeIntervalSince1970)).jpg"
            _ = try await ClientsService.uploadAttachment(clientId: clientId, data: jpegData, fileName: fileName)
            selectedImage = nil
            await loadAttachments()
        } catch {
            errorMessage = "Failed to upload: \(error.localizedDescription)"
        }
        isUploading = false
    }

    @MainActor
    private func deleteAttachment(_ attachment: AttachmentDTO) async {
        isLoading = true
        do {
            try await ClientsService.deleteAttachment(clientId: clientId, path: attachment.path)
            attachments.removeAll { $0.id == attachment.id }
            await loadAttachments()
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
        attachmentToDelete = nil
        isLoading = false
    }
}

struct PhotoThumbnail: View {
    let attachment: AttachmentDTO
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var isImageLoaded = false
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width
            ZStack(alignment: .topTrailing) {
                Button(action: onTap) {
                    AsyncImage(url: URL(string: attachment.fileUrl)) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: size, height: size)
                                .shimmer()
                                .onAppear {
                                    isImageLoaded = false
                                }
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size, height: size)
                                .clipped()
                                .onAppear {
                                    isImageLoaded = true
                                }
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                                .frame(width: size, height: size)
                                .onAppear {
                                    isImageLoaded = false
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                if isImageLoaded {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .font(.title3)
                    }
                    .padding(4)
                    .transition(.opacity)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct FullScreenPhotoView: View {
    let attachment: AttachmentDTO
    let onDismiss: () -> Void
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let url = URL(string: attachment.fileUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                        if scale < 1 {
                                            withAnimation {
                                                scale = 1
                                                lastScale = 1
                                            }
                                        }
                                    }
                            )
                    case .failure:
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                            Text("Failed to load photo")
                        }
                        .foregroundColor(.white)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
            }
        }
    }
}
