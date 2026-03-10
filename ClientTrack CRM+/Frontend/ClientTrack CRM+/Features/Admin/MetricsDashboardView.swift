//
//  MetricsDashboardView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Charts
import SwiftUI

struct MetricsDashboardView: View {
    @State private var metricsData: MetricsData?
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
                    Button("Retry") {
                        Task {
                            await loadMetrics()
                        }
                    }
                }
            } else if let data = metricsData {
                ScrollView {
                    VStack(spacing: 24) {
                        if let system = data.systemMetrics {
                            SystemMetricsSection(metrics: system)
                        }
                        if !data.httpRequests.isEmpty {
                            HTTPRequestsSection(requests: data.httpRequests)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(AppTheme.authBackgroundGradient.ignoresSafeArea())
        .navigationTitle("Metrics Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await loadMetrics()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
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
                let text = String(data: data, encoding: .utf8) ?? ""
                metricsData = PrometheusParser.parse(text)
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

struct SystemMetricsSection: View {
    let metrics: SystemMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Metrics")
                .font(.headline)
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                MetricCard(
                    title: "Memory",
                    value: formatBytes(metrics.memoryUsage),
                    icon: "memorychip",
                    color: .blue
                )
                MetricCard(
                    title: "CPU Time",
                    value: String(format: "%.2fs", metrics.cpuTime),
                    icon: "cpu",
                    color: .orange
                )
                MetricCard(
                    title: "Open Files",
                    value: "\(Int(metrics.openFDs))",
                    icon: "doc.text",
                    color: .green
                )
            }
        }
    }

    private func formatBytes(_ bytes: Double) -> String {
        let mb = bytes / 1_000_000
        return String(format: "%.1f MB", mb)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HTTPRequestsSection: View {
    let requests: [HTTPRequestMetric]
    private var topRequests: [HTTPRequestMetric] {
        Array(requests.sorted { $0.count > $1.count }.prefix(10))
    }

    private var totalRequests: Double {
        requests.reduce(0) { $0 + $1.count }
    }

    private var requestsByStatus: [(status: String, count: Double)] {
        Dictionary(grouping: requests, by: { $0.status })
            .map { (status: $0.key, count: $0.value.reduce(0) { $0 + $1.count }) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Requests")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(totalRequests))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            VStack(alignment: .leading, spacing: 8) {
                Text("Requests by Status")
                    .font(.headline)
                Chart(requestsByStatus, id: \.status) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Status", item.status)
                    )
                    .foregroundStyle(colorForStatus(item.status))
                }
                .frame(height: CGFloat(requestsByStatus.count) * 40)
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            VStack(alignment: .leading, spacing: 8) {
                Text("Top Endpoints")
                    .font(.headline)
                ForEach(topRequests.prefix(5)) { request in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(request.method)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(colorForMethod(request.method))
                                    .cornerRadius(4)
                                Text(request.status)
                                    .font(.caption)
                                    .foregroundColor(colorForStatus(request.status))
                            }
                            Text(request.path)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text("\(Int(request.count))")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    if request.id != topRequests.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private func colorForStatus(_ status: String) -> Color {
        switch status.prefix(1) {
        case "2": return .green
        case "3": return .blue
        case "4": return .orange
        case "5": return .red
        default: return .gray
        }
    }

    private func colorForMethod(_ method: String) -> Color {
        switch method {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        case "PATCH": return .white
        default: return .gray
        }
    }
}
