//
//  AdminPanelView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct AdminPanelView: View {
    @EnvironmentObject var authState: AuthState
    var body: some View {
        List {
            Section {
                NavigationLink {
                    AdminUsersListView()
                        .environmentObject(authState)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Manage Users")
                            .foregroundColor(.white)
                    }
                }
                NavigationLink {
                    MetricsDashboardView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("View Metrics")
                            .foregroundColor(.white)
                    }
                }
            } header: {
                Text("Administration")
            } footer: {
                Text("Admin-only features. Use with caution.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Section {
                HStack {
                    Text("Role")
                    Spacer()
                    Text(authState.currentUser?.role ?? "Unknown")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Email")
                    Spacer()
                    Text(authState.currentUser?.email ?? "Unknown")
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            } header: {
                Text("Your Info")
            }
        }
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .background(AppTheme.authBackgroundGradient.ignoresSafeArea())
        .navigationTitle("Admin Panel")
        .navigationBarTitleDisplayMode(.inline)
    }
}
