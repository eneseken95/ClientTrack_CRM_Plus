//
//  MetricsView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct MetricsView: View {
    @State private var metricsText: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading metrics...")
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else {
                ScrollView {
                    Text(metricsText)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                }
            }
        }
        .navigationTitle("Metrics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadMetrics()
        }
    }

    @MainActor
    private func loadMetrics() async {
        isLoading = true
        errorMessage = nil
        do {
            let baseURL = AppConfig.baseURL.absoluteString.replacingOccurrences(of: "/api/v1", with: "")
            guard let url = URL(string: "\(baseURL)/metrics") else {
                errorMessage = "Invalid URL"
                isLoading = false
                return
            }
            var request = URLRequest(url: url)
            if let token = TokenStore.shared.accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                errorMessage = "Not authenticated"
                isLoading = false
                return
            }
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid response"
                isLoading = false
                return
            }
            if httpResponse.statusCode == 200 {
                metricsText = String(data: data, encoding: .utf8) ?? "Unable to decode metrics"
            } else {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                errorMessage = "HTTP \(httpResponse.statusCode): \(errorText)"
            }
        } catch {
            errorMessage = "Failed to load metrics: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
