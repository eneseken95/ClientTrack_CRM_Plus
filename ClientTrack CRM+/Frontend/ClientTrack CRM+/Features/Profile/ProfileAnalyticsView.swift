//
//  ProfileAnalyticsView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 21.02.2026.
//

import Charts
import SwiftUI

struct ProfileAnalyticsView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var vm = ProfileAnalyticsViewModel()
    @State private var showSubscriptionSheet = false
    private var isPremium: Bool {
        authState.currentUser?.subscription_status == "active"
    }

    private let statusColors: [Color] = [
        Color(red: 0.30, green: 0.85, blue: 0.55),
        Color(red: 0.35, green: 0.60, blue: 1.0),
        Color(red: 0.95, green: 0.45, blue: 0.45),
        Color(red: 0.90, green: 0.65, blue: 0.20),
        Color(red: 0.70, green: 0.45, blue: 1.0),
        Color(red: 0.30, green: 0.80, blue: 0.85)
    ]

    private var displayStatusData: [StatusClientData] {
        if isPremium {
            return vm.statusData.isEmpty ? [
                StatusClientData(status: "Active", count: 1),
                StatusClientData(status: "Pending", count: 1),
                StatusClientData(status: "Closed", count: 1)
            ] : vm.statusData
        } else {
            return vm.statusData.isEmpty ? [
                StatusClientData(status: "Active", count: 42),
                StatusClientData(status: "Pending", count: 28),
                StatusClientData(status: "Closed", count: 12)
            ] : vm.statusData
        }
    }

    private var displayCategoryData: [ChartData] {
        if isPremium {
            return vm.categoryData.isEmpty ? [
                ChartData(label: "Consulting", count: 1, color: .gray.opacity(0.3)),
                ChartData(label: "Product", count: 1, color: .gray.opacity(0.3)),
                ChartData(label: "Service", count: 1, color: .gray.opacity(0.3))
            ] : vm.categoryData
        } else {
            return vm.categoryData.isEmpty ? [
                ChartData(label: "Consulting", count: 35, color: .blue),
                ChartData(label: "Product", count: 20, color: .purple),
                ChartData(label: "Service", count: 15, color: .cyan)
            ] : vm.categoryData
        }
    }

    private var displayIndustryData: [ChartData] {
        if isPremium {
            return vm.industryData.isEmpty ? [
                ChartData(label: "Technology", count: 1, color: .gray.opacity(0.3)),
                ChartData(label: "Finance", count: 1, color: .gray.opacity(0.3)),
                ChartData(label: "Healthcare", count: 1, color: .gray.opacity(0.3))
            ] : vm.industryData
        } else {
            return vm.industryData.isEmpty ? [
                ChartData(label: "Technology", count: 40, color: .orange),
                ChartData(label: "Finance", count: 30, color: .red),
                ChartData(label: "Healthcare", count: 18, color: .pink)
            ] : vm.industryData
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.authBackgroundGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        overviewSection
                        monthlyChartSection
                        advancedAnalyticsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .padding(.top, 15)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Dashboard")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await vm.load()
            }
            .sheet(isPresented: $showSubscriptionSheet) {
                NavigationStack {
                    SubscriptionView(isPresentedAsSheet: true)
                }
            }
        }
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 4)
            HStack(spacing: 14) {
                miniStatCard(
                    icon: "person.2.fill",
                    iconColor: .green,
                    title: "Total Clients",
                    value: vm.isLoading ? "..." : "\(vm.totalClients)"
                )
                miniStatCard(
                    icon: "calendar.badge.plus",
                    iconColor: .orange,
                    title: "This Month",
                    value: vm.isLoading ? "..." : "\(vm.clientsThisMonth)"
                )
            }
        }
    }

    private var monthlyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clients Per Month")
                .font(.headline)
                .foregroundColor(.white)
            if vm.isLoading {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.12))
                    .frame(height: 220)
                    .shimmer()
            } else {
                Chart(vm.monthlyData) { item in
                    LineMark(
                        x: .value("Month", item.month),
                        y: .value("Clients", item.count)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(Color.pink)
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                    .symbolSize(40)
                    AreaMark(
                        x: .value("Month", item.month),
                        y: .value("Clients", item.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.pink.opacity(0.4), Color.pink.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    PointMark(
                        x: .value("Month", item.month),
                        y: .value("Clients", item.count)
                    )
                    .foregroundStyle(.white)
                    .annotation(position: .top, spacing: 6) {
                        Text("\(item.count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.pink.opacity(0.7))
                            )
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 3]))
                            .foregroundStyle(Color.white.opacity(0.15))
                        AxisTick(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(Color.white.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.7))
                            .font(.caption2)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [3, 4]))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.7))
                            .font(.caption)
                    }
                }
                .frame(height: 220)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var advancedAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced Analytics")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            ZStack {
                VStack(spacing: 24) {
                    clientGrowthTrendCard
                    statusTrendCard
                    if !displayStatusData.isEmpty {
                        statusChartCard
                    }
                    if !displayCategoryData.isEmpty {
                        categoryChartCard
                    }
                    if !displayIndustryData.isEmpty {
                        industryChartCard
                    }
                }
                .blur(radius: isPremium ? 0 : 8)
                .disabled(!isPremium)
                .padding(.top, 10)
                if !isPremium {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                        Text("Pro Feature")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                        Text("Unlock detailed insights and status distributions by upgrading.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                        Button {
                            showSubscriptionSheet = true
                        } label: {
                            Text("Upgrade Plan")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(AppTheme.primary)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statusChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cases by Status")
                .font(.headline)
                .foregroundColor(.white)

            Chart(Array(displayStatusData.enumerated()), id: \.element.id) { index, item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Status", item.status)
                )
                .cornerRadius(4)
                .foregroundStyle(statusColors[index % statusColors.count])
                .annotation(position: .trailing, alignment: .leading) {
                    Text("\(vm.statusData.isEmpty ? 0 : item.count)")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(height: max(100, CGFloat(displayStatusData.count) * 50))
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }

            if vm.statusData.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, -8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var categoryChartCard: some View {
        let total = displayCategoryData.reduce(0) { $0 + $1.count }
        return VStack(alignment: .leading, spacing: 16) {
            Text("Cases by Category")
                .font(.headline)
                .foregroundColor(.white)

            Chart(displayCategoryData) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.80),
                    angularInset: 1.5
                )
                .cornerRadius(2)
                .foregroundStyle(item.color)
            }
            .frame(height: 180)
            .chartLegend(.hidden)

            VStack(spacing: 6) {
                ForEach(displayCategoryData) { item in
                    let pct = total > 0 ? (item.count * 100 / total) : 0
                    HStack(spacing: 6) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 8, height: 8)
                        Text("\(pct)% \(item.label)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)

            if vm.categoryData.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, -8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var industryChartCard: some View {
        let total = displayIndustryData.reduce(0) { $0 + $1.count }
        return VStack(alignment: .leading, spacing: 16) {
            Text("Cases by Industry")
                .font(.headline)
                .foregroundColor(.white)

            Chart(displayIndustryData) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.80),
                    angularInset: 1.5
                )
                .cornerRadius(2)
                .foregroundStyle(item.color)
            }
            .frame(height: 180)
            .chartLegend(.hidden)

            VStack(spacing: 6) {
                ForEach(displayIndustryData) { item in
                    let pct = total > 0 ? (item.count * 100 / total) : 0
                    HStack(spacing: 6) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 8, height: 8)
                        Text("\(pct)% \(item.label)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)

            if vm.industryData.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, -8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var clientGrowthTrendCard: some View {
        TrendLineChartCard(
            title: "Client Growth",
            trendData: vm.clientGrowthTrend,
            lineColor: Color(red: 0.30, green: 0.85, blue: 0.55),
            secondaryLineColor: Color(red: 0.35, green: 0.60, blue: 1.0),
            isLoading: vm.isLoading
        )
    }

    private var statusTrendCard: some View {
        StatusTrendChartCard(
            title: "Status Trends",
            statusTrendMap: vm.statusTrendMap,
            isLoading: vm.isLoading
        )
    }

    private func miniStatCard(icon: String, iconColor: Color, title: String, value: String) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
            }
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    struct MonthlyClientData: Identifiable {
        let id = UUID()
        let month: String
        let count: Int
    }

    struct StatusClientData: Identifiable {
        let id = UUID()
        let status: String
        let count: Int
    }

    struct ChartData: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let color: Color
    }

    struct TrendDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let label: String
        let count: Int
    }

    enum TimePeriod: String, CaseIterable {
        case oneMonth = "1 Month"
        case threeMonths = "3 Months"
        case sixMonths = "6 Months"
        case lastYear = "Last Year"

        var monthsBack: Int {
            switch self {
            case .oneMonth: return 1
            case .threeMonths: return 3
            case .sixMonths: return 6
            case .lastYear: return 12
            }
        }
    }

    @MainActor
    final class ProfileAnalyticsViewModel: ObservableObject {
        @Published var totalClients = 0
        @Published var clientsThisMonth = 0
        @Published var monthlyData: [MonthlyClientData] = []
        @Published var statusData: [StatusClientData] = []
        @Published var clients: [ClientDTO] = []
        @Published var categoryData: [ChartData] = []
        @Published var industryData: [ChartData] = []
        @Published var clientGrowthTrend: [TrendDataPoint] = []
        @Published var statusTrendMap: [String: [TrendDataPoint]] = [:]
        @Published var isLoading = false
        func load() async {
            isLoading = true
            defer { isLoading = false }
            do {
                let response = try await ClientsService.fetch(page: 1, size: 1000)
                let fetchedClients = response.items
                self.clients = fetchedClients
                totalClients = response.meta.total
                let now = Date()
                let calendar = Calendar.current
                let currentMonth = calendar.component(.month, from: now)
                let currentYear = calendar.component(.year, from: now)
                clientsThisMonth = fetchedClients.filter { client in
                    guard let date = client.createdAt else { return false }
                    return calendar.component(.month, from: date) == currentMonth
                        && calendar.component(.year, from: date) == currentYear
                }.count
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                var monthly: [MonthlyClientData] = []
                for i in (0 ..< 6).reversed() {
                    guard let monthDate = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
                    let m = calendar.component(.month, from: monthDate)
                    let y = calendar.component(.year, from: monthDate)
                    let count = fetchedClients.filter { client in
                        guard let date = client.createdAt else { return false }
                        return calendar.component(.month, from: date) == m
                            && calendar.component(.year, from: date) == y
                    }.count
                    monthly.append(MonthlyClientData(month: formatter.string(from: monthDate), count: count))
                }
                monthlyData = monthly
                var statusCounts: [String: Int] = [:]
                for client in fetchedClients {
                    let s = client.status ?? "Unknown"
                    statusCounts[s, default: 0] += 1
                }
                statusData = statusCounts.map { StatusClientData(status: $0.key, count: $0.value) }
                    .sorted { $0.count > $1.count }

                let catGrouped = Dictionary(grouping: fetchedClients, by: { $0.category ?? "Unknown" })
                let catColors: [Color] = [.blue, .purple, .pink, .orange, .green, .cyan, .teal, .indigo]
                self.categoryData = catGrouped.sorted(by: { $0.value.count > $1.value.count }).enumerated().map { index, pair in
                    return ChartData(label: pair.key, count: pair.value.count, color: catColors[index % catColors.count])
                }

                let indGrouped = Dictionary(grouping: fetchedClients, by: { $0.industry ?? "Unknown" })
                let indColors: [Color] = [.orange, .red, .mint, .purple, .indigo, .blue, .cyan, .teal]
                self.industryData = indGrouped.sorted(by: { $0.value.count > $1.value.count }).enumerated().map { index, pair in
                    return ChartData(label: pair.key, count: pair.value.count, color: indColors[index % indColors.count])
                }

                let trendFormatter = DateFormatter()
                trendFormatter.dateFormat = "MMM"
                var growthTrend: [TrendDataPoint] = []
                var statusTrends: [String: [TrendDataPoint]] = [:]
                let allStatuses = Set(fetchedClients.compactMap { $0.status ?? "Unknown" })

                for i in (0 ..< 12).reversed() {
                    guard let monthDate = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
                    let m = calendar.component(.month, from: monthDate)
                    let y = calendar.component(.year, from: monthDate)
                    let monthClients = fetchedClients.filter { client in
                        guard let date = client.createdAt else { return false }
                        return calendar.component(.month, from: date) == m
                            && calendar.component(.year, from: date) == y
                    }
                    growthTrend.append(TrendDataPoint(
                        date: monthDate,
                        label: trendFormatter.string(from: monthDate),
                        count: monthClients.count
                    ))
                    for status in allStatuses {
                        let count = monthClients.filter { ($0.status ?? "Unknown") == status }.count
                        statusTrends[status, default: []].append(TrendDataPoint(
                            date: monthDate,
                            label: trendFormatter.string(from: monthDate),
                            count: count
                        ))
                    }
                }
                clientGrowthTrend = growthTrend
                statusTrendMap = statusTrends

            } catch {}
        }
    }
}

struct TrendLineChartCard: View {
    let title: String
    let trendData: [ProfileAnalyticsView.TrendDataPoint]
    let lineColor: Color
    let secondaryLineColor: Color
    let isLoading: Bool

    @State private var selectedPeriod: ProfileAnalyticsView.TimePeriod = .sixMonths

    private var filteredData: [ProfileAnalyticsView.TrendDataPoint] {
        let count = selectedPeriod.monthsBack
        return Array(trendData.suffix(count))
    }

    private var currentTotal: Int {
        filteredData.reduce(0) { $0 + $1.count }
    }

    private var previousTotal: Int {
        let count = selectedPeriod.monthsBack
        let allData = trendData
        let endIndex = allData.count - count
        guard endIndex > 0 else { return 0 }
        let startIndex = max(0, endIndex - count)
        return allData[startIndex..<endIndex].reduce(0) { $0 + $1.count }
    }

    private var growthPercentage: Double {
        guard previousTotal > 0 else { return currentTotal > 0 ? 100 : 0 }
        return Double(currentTotal - previousTotal) / Double(previousTotal) * 100
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    HStack(spacing: 12) {
                        Text("\(currentTotal)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(lineColor)
                        HStack(spacing: 3) {
                            Image(systemName: growthPercentage >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 10, weight: .bold))
                            Text(String(format: "%.1f%%", abs(growthPercentage)))
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(growthPercentage >= 0 ? lineColor : Color(red: 0.95, green: 0.45, blue: 0.45))
                    }
                }
                Spacer()
                Text(dateString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            HStack(spacing: 0) {
                ForEach(ProfileAnalyticsView.TimePeriod.allCases, id: \.self) { period in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(selectedPeriod == period ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedPeriod == period ? Color.white.opacity(0.15) : .clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(selectedPeriod == period ? Color.white.opacity(0.25) : .clear, lineWidth: 1)
                                    )
                            )
                    }
                }
            }

            if isLoading {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.12))
                    .frame(height: 160)
                    .shimmer()
            } else {
                Chart(filteredData) { item in
                    LineMark(
                        x: .value("Month", item.label),
                        y: .value("Count", item.count)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .foregroundStyle(lineColor)

                    AreaMark(
                        x: .value("Month", item.label),
                        y: .value("Count", item.count)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [lineColor.opacity(0.3), lineColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [4, 3]))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.5))
                            .font(.system(size: 10))
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.5))
                            .font(.system(size: 10))
                    }
                }
                .frame(height: 160)
                .animation(.easeInOut(duration: 0.4), value: selectedPeriod)
            }
        }
        .padding(16)
        .background(
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
        )
    }
}

struct StatusTrendChartCard: View {
    let title: String
    let statusTrendMap: [String: [ProfileAnalyticsView.TrendDataPoint]]
    let isLoading: Bool

    @State private var selectedPeriod: ProfileAnalyticsView.TimePeriod = .sixMonths

    private let trendColors: [Color] = [
        Color(red: 0.35, green: 0.60, blue: 1.0),
        Color(red: 0.30, green: 0.85, blue: 0.55),
        Color(red: 0.95, green: 0.45, blue: 0.45),
        Color(red: 0.90, green: 0.65, blue: 0.20),
        Color(red: 0.70, green: 0.45, blue: 1.0),
        Color(red: 0.30, green: 0.80, blue: 0.85)
    ]

    private struct StatusLine: Identifiable {
        let id = UUID()
        let status: String
        let data: [ProfileAnalyticsView.TrendDataPoint]
        let color: Color
        let latestCount: Int
        let percentage: Double
    }

    private var statusLines: [StatusLine] {
        let sortedStatuses = statusTrendMap.sorted { a, b in
            let aTotal = a.value.reduce(0) { $0 + $1.count }
            let bTotal = b.value.reduce(0) { $0 + $1.count }
            return aTotal > bTotal
        }
        let grandTotal = sortedStatuses.reduce(0) { sum, pair in
            sum + pair.value.suffix(selectedPeriod.monthsBack).reduce(0) { $0 + $1.count }
        }
        return sortedStatuses.enumerated().map { index, pair in
            let filtered = Array(pair.value.suffix(selectedPeriod.monthsBack))
            let total = filtered.reduce(0) { $0 + $1.count }
            let pct = grandTotal > 0 ? (Double(total) / Double(grandTotal) * 100) : 0
            return StatusLine(
                status: pair.key,
                data: filtered,
                color: trendColors[index % trendColors.count],
                latestCount: filtered.last?.count ?? 0,
                percentage: pct
            )
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(dateString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(statusLines) { line in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(line.color)
                            .frame(width: 7, height: 7)
                        Text(line.status)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                        Text(String(format: "%.1f%%", line.percentage))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(line.color)
                    }
                }
            }

            HStack(spacing: 0) {
                ForEach(ProfileAnalyticsView.TimePeriod.allCases, id: \.self) { period in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(selectedPeriod == period ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedPeriod == period ? Color.white.opacity(0.15) : .clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(selectedPeriod == period ? Color.white.opacity(0.25) : .clear, lineWidth: 1)
                                    )
                            )
                    }
                }
            }

            if isLoading {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.12))
                    .frame(height: 180)
                    .shimmer()
            } else {
                Chart {
                    ForEach(statusLines) { line in
                        ForEach(line.data) { point in
                            LineMark(
                                x: .value("Month", point.label),
                                y: .value("Count", point.count),
                                series: .value("Status", line.status)
                            )
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                            .foregroundStyle(line.color)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [4, 3]))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.5))
                            .font(.system(size: 10))
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.5))
                            .font(.system(size: 10))
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 180)
                .animation(.easeInOut(duration: 0.4), value: selectedPeriod)
            }
        }
        .padding(16)
        .background(
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
        )
    }
}
