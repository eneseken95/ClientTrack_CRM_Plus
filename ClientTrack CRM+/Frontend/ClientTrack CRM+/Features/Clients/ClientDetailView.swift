//
//  ClientDetailView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import MapKit
import SwiftUI

struct ClientDetailView: View {
    let client: ClientDTO
    let onDelete: (() -> Void)?
    @StateObject private var vm: ClientDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showNavBarTitle = false
    @State private var showEditClient = false
    init(client: ClientDTO, onDelete: (() -> Void)? = nil) {
        self.client = client
        self.onDelete = onDelete
        _vm = StateObject(wrappedValue: ClientDetailViewModel(client: client))
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
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
                    VStack(spacing: 4) {
                        if let company = vm.client.company {
                            Text(company)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        } else {
                            Text("\(vm.client.name) \(vm.client.surname ?? "")")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        if let email = vm.client.email, !email.isEmpty {
                            Text(email)
                                .font(.body)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 0)
                .background(
                    GeometryReader { geo in
                        Color.clear.onChange(of: geo.frame(in: .global).maxY) { _, maxY in
                            if maxY < 100 {
                                showNavBarTitle = true
                            } else {
                                showNavBarTitle = false
                            }
                        }
                    }
                )
            }
            .listRowBackground(Color.clear)
            Section {
                NavigationLink {
                    ChangeClientAvatarView(vm: vm)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Change logo")
                            .foregroundColor(.white)
                    }
                }
                .disabled(vm.isSaving)
                NavigationLink {
                    DeleteClientAvatarView(vm: vm)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Delete logo")
                            .foregroundColor(.white)
                    }
                }
                .disabled(vm.client.companyLogo == nil || vm.isSaving)
            } header: {
                Text("Avatar")
                    .foregroundColor(.gray)
            }
            Section {
                clientRow(icon: "person.fill", color: .blue, title: "Name", value: vm.client.name)
                clientRow(icon: "person.fill", color: .teal, title: "Surname", value: vm.client.surname)
                clientRow(icon: "envelope.fill", color: .pink, title: "Email", value: vm.client.email)
                clientRow(icon: "phone.fill", color: .green, title: "Phone", value: vm.client.phone)
            } header: {
                Text("Contact")
            }
            if vm.client.company != nil || vm.client.industry != nil ||
                vm.client.category != nil || vm.client.status != nil ||
                vm.client.source != nil
            {
                Section {
                    clientRow(icon: "building.2.fill", color: .indigo, title: "Company", value: vm.client.company)
                    clientRow(icon: "briefcase.fill", color: .brown, title: "Industry", value: vm.client.industry)
                    clientRow(icon: "tag.fill", color: .cyan, title: "Category", value: vm.client.category)
                    if let status = vm.client.status {
                        HStack(spacing: 12) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(AppTheme.statusColor(for: status))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text("Status")
                            Spacer()
                            Text(status)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.statusColor(for: status).opacity(0.12))
                                )
                                .foregroundColor(AppTheme.statusColor(for: status))
                        }
                    }
                    clientRow(icon: "link.circle.fill", color: .mint, title: "Source", value: vm.client.source)
                } header: {
                    Text("Company")
                }
            }
            if let latString = vm.client.latitude, let lonString = vm.client.longitude,
               let lat = Double(latString), let lon = Double(lonString)
            {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                Section {
                    Map(position: .constant(.region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))))) {
                        Annotation(vm.client.company ?? vm.client.name, coordinate: coordinate) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                                .background(Color.white.clipShape(Circle()))
                        }
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                    .allowsHitTesting(false)
                } header: {
                    Text("Location")
                }
            }
            if let notes = vm.client.notes, !notes.isEmpty {
                Section {
                    Text(notes)
                        .font(.body)
                } header: {
                    Text("Notes")
                }
            }
            Section {
                Button {
                    showEditClient = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Edit Client")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
                NavigationLink {
                    ClientEmailsView(clientId: vm.client.id, clientName: vm.client.name)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.pink)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Emails")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                NavigationLink {
                    ClientAttachmentsView(clientId: vm.client.id, clientName: vm.client.name)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Photos")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Delete Client")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
            } header: {
                Text("Actions")
                    .foregroundColor(.gray)
            }
        }
        .coordinateSpace(name: "scroll")
        .listStyle(.insetGrouped)
        .offset(y: -35)
        .padding(.bottom, -35)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .background(AppTheme.authBackgroundGradient.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(showNavBarTitle ? .visible : .hidden, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    CompanyLogoImage(
                        logoUrl: vm.client.companyLogo,
                        companyName: vm.client.company ?? vm.client.name,
                        size: 27
                    )
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.client.company ?? "\(vm.client.name) \(vm.client.surname ?? "")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        if let email = vm.client.email, !email.isEmpty {
                            Text(email)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .opacity(showNavBarTitle ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showNavBarTitle)
            }
        }
        .sheet(isPresented: $showEditClient) {
            EditClientView(vm: vm)
        }
        .alert("Delete Client?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    let success = await vm.deleteClient()
                    if success {
                        await MainActor.run {
                            dismiss()
                        }
                    } else {}
                }
            }
        } message: {
            Text("This will permanently delete this client and all related data.")
        }
    }

    private func clientRow(icon: String, color: Color, title: String, value: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text(title)
            Spacer()
            Text((value?.isEmpty == false) ? value! : "—")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        ClientDetailView(client: ClientDTO(
            id: 1,
            name: "John",
            surname: "Doe",
            email: "john.doe@example.com",
            phone: "+1 555-0123",
            company: "Acme Corporation",
            notes: "Important client with high-value projects. Prefers email communication.",
            source: "Referral",
            status: "Active",
            category: "Enterprise",
            industry: "Technology",
            latitude: nil,
            longitude: nil,
            createdAt: Date(),
            companyLogo: nil
        ), onDelete: nil)
    }
    .environmentObject(AuthState())
}
