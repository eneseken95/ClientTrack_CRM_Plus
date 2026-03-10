//
//  SearchView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @EnvironmentObject var authState: AuthState
    @FocusState private var isSearchFocused: Bool
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.authBackgroundGradient.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search clients by name, company, email...", text: $vm.searchQuery)
                            .foregroundColor(.white)
                            .focused($isSearchFocused)
                        if !vm.searchQuery.isEmpty {
                            Button {
                                vm.searchQuery = ""
                                isSearchFocused = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 8)
                    Group {
                        if vm.searchQuery.isEmpty {
                            allClientsListView
                        } else if vm.isSearching {
                            loadingView
                        } else if let error = vm.errorMessage {
                            errorView(message: error)
                        } else if vm.searchResults.isEmpty {
                            noResultsView
                        } else {
                            resultsListView
                        }
                    }
                    Spacer()
                }
            }
            .navigationTitle("Search")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await vm.loadAllClients()
            }
        }
    }

    private var allClientsListView: some View {
        Group {
            if vm.isLoadingAll {
                loadingView
            } else {
                List {
                    Section {
                        ForEach(vm.allClients) { client in
                            NavigationLink {
                                ClientDetailView(client: client)
                            } label: {
                                SearchResultRow(client: client)
                            }
                        }
                    } header: {
                        Text("\(vm.allClients.count) client\(vm.allClients.count == 1 ? "" : "s")")
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
            }
        }
    }

    private var loadingView: some View {
        List {
            ForEach(0 ..< 5, id: \.self) { _ in
                HStack(spacing: 12) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primary.opacity(0.08), AppTheme.accent.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shimmer()
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 16)
                            .shimmer()
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.12))
                            .frame(height: 14)
                            .frame(maxWidth: 200)
                            .shimmer()
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.statusPending.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .blur(radius: 10)
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(AppTheme.statusPending)
            }
            Text("Search Error")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            GradientButton(title: "Try Again") {
                vm.retry()
            }
            .frame(width: 180)
        }
        .padding(.top, 80)
    }

    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 52, weight: .light))
                .foregroundColor(.secondary)
            Text("No Results")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("No clients found matching '\(vm.searchQuery)'")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 180)
    }

    private var resultsListView: some View {
        List {
            Section {
                ForEach(vm.searchResults) { client in
                    NavigationLink {
                        ClientDetailView(client: client)
                    } label: {
                        SearchResultRow(client: client)
                    }
                }
            } header: {
                Text("\(vm.searchResults.count) result\(vm.searchResults.count == 1 ? "" : "s") found")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }
}

struct SearchResultRow: View {
    let client: ClientDTO

    var body: some View {
        HStack(spacing: 14) {
            CompanyLogoImage(
                logoUrl: client.companyLogo,
                companyName: client.company,
                size: 50
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
            VStack(alignment: .leading, spacing: 6) {
                Text(client.name + (client.surname.map { " \($0)" } ?? ""))
                    .font(.headline)
                    .foregroundColor(.white)
                if let company = client.company {
                    Text(company)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let email = client.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(AppTheme.primary)
                } else if let phone = client.phone {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
