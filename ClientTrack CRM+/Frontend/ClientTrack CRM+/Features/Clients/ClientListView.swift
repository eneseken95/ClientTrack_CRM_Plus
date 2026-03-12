//
//  ClientListView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct ClientListView: View {
    @StateObject private var vm = ClientListViewModel()
    @StateObject private var profileVM = ProfileViewModel()
    @State private var showCreate = false
    @State private var showSubscriptionPaywall = false
    @State private var showSearchPaywall = false
    @State private var showSubscriptionSheet = false
    @State private var navigationPath = NavigationPath()
    @EnvironmentObject var authState: AuthState
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                customSearchBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .padding(.bottom, -10)
                    .zIndex(1)
                List {
                    if case .loadingInitial = vm.state {
                        Section {
                            ForEach(0 ..< 6, id: \.self) { _ in
                                ClientListPlaceholder()
                                    .listRowBackground(Color.clear)
                                    .allowsHitTesting(false)
                            }
                        }
                    } else if vm.filteredClients.isEmpty {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.subtleGradient)
                                    .frame(width: 110, height: 110)
                                    .blur(radius: 10)
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                    .font(.system(size: 50, weight: .light))
                                    .foregroundStyle(AppTheme.primaryGradient)
                            }
                            Text("No clients found.")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * 0.6, alignment: .center)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(vm.filteredClients, id: \.id) { client in
                            NavigationLink {
                                ClientDetailView(client: client)
                            } label: {
                                HStack(spacing: 12) {
                                    CompanyLogoImage(
                                        logoUrl: client.companyLogo,
                                        companyName: client.company,
                                        size: 42
                                    )
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [AppTheme.primary.opacity(0.2), AppTheme.accent.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                                    .shadow(color: AppTheme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            if let company = client.company {
                                                Text(company)
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                            } else {
                                                Text("No Company")
                                                    .font(.headline)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            if let status = client.status {
                                                Text(status)
                                                    .font(.caption2)
                                                    .fontWeight(.semibold)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 4)
                                                    .background(
                                                        Capsule()
                                                            .fill(AppTheme.statusColor(for: status).opacity(0.12))
                                                    )
                                                    .foregroundColor(AppTheme.statusColor(for: status))
                                            }
                                        }
                                        HStack(spacing: 6) {
                                            if let category = client.category {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "tag.fill")
                                                        .font(.system(size: 9))
                                                    Text(category)
                                                        .font(.caption)
                                                }
                                                .foregroundColor(AppTheme.textSecondary)
                                            }
                                            if client.category != nil && client.industry != nil {
                                                Text("·")
                                                    .font(.caption)
                                                    .foregroundColor(AppTheme.textTertiary)
                                            }
                                            if let industry = client.industry {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "building.2.fill")
                                                        .font(.system(size: 9))
                                                    Text(industry)
                                                        .font(.caption)
                                                }
                                                .foregroundColor(AppTheme.textSecondary)
                                            }
                                        }
                                    }
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 22, leading: 16, bottom: 22, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                    .padding(.vertical, 4)
                            )
                            .onAppear {
                                Task {
                                    await vm.loadMoreIfNeeded(currentItem: client)
                                }
                            }
                        }
                    }
                    if case .loadingMore = vm.state {
                        HStack {
                            Spacer()
                            ProgressView()
                                .tint(AppTheme.primary)
                            Spacer()
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .padding(.top, -16)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .background(Color.clear)
            }
            .background(AppTheme.authBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Clients")
            .navigationDestination(for: ProfileView.Route.self) { route in
                switch route {
                case .changeAvatar:
                    ChangeAvatarView(vm: profileVM)
                case .deleteAvatar:
                    DeleteAvatarView(vm: profileVM)
                }
            }
            .task {
                await vm.onViewAppear()
            }
            .onAppear {
                Task {
                    await vm.refresh()
                }
            }
            .refreshable {
                await vm.refresh()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if authState.currentUser?.subscription_status != "active" && vm.totalClients >= 50 {
                            showSubscriptionPaywall = true
                        } else {
                            showCreate = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.primaryGradient)
                    }
                }
            }
            .alert(isPresented: .constant(isError)) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showCreate) {
                ClientCreateView { newClient in
                    vm.addClientToTop(newClient)
                }
            }
            .alert("Pro Feature", isPresented: $showSubscriptionPaywall) {
                Button("Upgrade Plan") {
                    showSubscriptionSheet = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You've reached the client limit on the Basic plan. Please upgrade your plan to add unlimited clients.")
            }
            .alert("Pro Feature", isPresented: $showSearchPaywall) {
                Button("Upgrade Plan") {
                    showSubscriptionSheet = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Search feature requires an active subscription. Please upgrade your plan.")
            }
            .sheet(isPresented: $showSubscriptionSheet) {
                NavigationStack {
                    SubscriptionView(isPresentedAsSheet: true)
                }
            }
        }
    }

    private var customSearchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            ZStack(alignment: .leading) {
                if vm.searchText.isEmpty {
                    Text("Search clients...")
                        .foregroundColor(.gray)
                }
                TextField("", text: $vm.searchText)
                    .disabled(authState.currentUser?.subscription_status != "active")
            }
            .frame(maxWidth: .infinity)
            if !vm.searchText.isEmpty {
                Button {
                    vm.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(red: 0.11, green: 0.11, blue: 0.14))
        .cornerRadius(10)
        .onTapGesture {
            if authState.currentUser?.subscription_status != "active" {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                showSearchPaywall = true
            }
        }
    }

    private var isError: Bool {
        if case .error = vm.state { return true }
        return false
    }

    private var errorMessage: String {
        if case let .error(msg) = vm.state { return msg }
        return ""
    }
}
