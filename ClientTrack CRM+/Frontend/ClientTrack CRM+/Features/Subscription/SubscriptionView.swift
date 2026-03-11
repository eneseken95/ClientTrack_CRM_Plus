//
//  SubscriptionView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 23.02.2026.
//

import StripePaymentSheet
import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) private var dismiss
    var isPresentedAsSheet: Bool = false
    @State private var isLoading = false
    @State private var isVerifying = true
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var paymentSheet: PaymentSheet?
    @State private var isPaymentSheetPresented = false
    @State private var isYearly = false
    @State private var selectedPlan = 1
    @State private var isRestoring = false
    @State private var prices: [String: String] = [:]
    @State private var isLoadingPrices = true
    @State private var isCanceling = false
    @State private var showCancelConfirmation = false
    private var isSubscribed: Bool {
        authState.currentUser?.subscription_status == "active"
    }
    
    private var planName: String {
        guard let planId = authState.currentUser?.subscription_plan_id else { return "Pro" }
        if planId.contains("basic") { return "Basic" }
        if planId.contains("team") { return "Team" }
        return "Pro"
    }

    private let accentBlue = Color(red: 0.25, green: 0.47, blue: 0.95)
    private let accentGold = Color(red: 0.85, green: 0.65, blue: 0.13)
    private let cardBg = Color(red: 0.11, green: 0.11, blue: 0.14)
    private let cardBorder = Color.white.opacity(0.08)

    var body: some View {
        ZStack {
            AppTheme.authBackgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: -4) {
                        HStack(spacing: -25) {
                            Image("ChartPurple")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 110, height: 110)
                            Text("CRM+")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.70, green: 0.45, blue: 1.0), Color(red: 0.55, green: 0.78, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .offset(x: -20)
                        .padding(.bottom, -25)
                        Text(isSubscribed ? "Your Subscription Plan" : "Upgrade Your Plan")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        Text(isSubscribed ? "You are currently subscribed to the \(planName) Plan." : "Choose the best plan for your business.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 8)
                    }
                    if !isSubscribed {
                        HStack(spacing: 0) {
                            toggleButton(title: "Monthly", isSelected: !isYearly) {
                                withAnimation(.easeInOut(duration: 0.2)) { isYearly = false }
                            }
                            toggleButton(title: "Yearly", isSelected: isYearly, badge: "Save 20%") {
                                withAnimation(.easeInOut(duration: 0.2)) { isYearly = true }
                            }
                        }
                        .padding(3)
                        .background(
                            Capsule().fill(Color.white.opacity(0.06))
                        )
                        .padding(.horizontal, 60)
                    }
                    if isSubscribed {
                        activeSubscriptionCard
                    } else {
                        ZStack {
                            basicPlanCard
                                .frame(width: 260, height: 370)
                                .scaleEffect(selectedPlan == 0 ? 1.0 : 0.85)
                                .offset(x: offsetForCard(0))
                                .zIndex(selectedPlan == 0 ? 2 : 0)
                            teamPlanCard
                                .frame(width: 260, height: 370)
                                .scaleEffect(selectedPlan == 2 ? 1.0 : 0.85)
                                .offset(x: offsetForCard(2))
                                .zIndex(selectedPlan == 2 ? 2 : 0)
                            proPlanCard
                                .frame(width: 260, height: 370)
                                .scaleEffect(selectedPlan == 1 ? 1.0 : 0.85)
                                .offset(x: offsetForCard(1))
                                .zIndex(selectedPlan == 1 ? 2 : 0)
                        }
                        .frame(height: 420)
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        if value.translation.width < -50 {
                                            selectedPlan = min(selectedPlan + 1, 2)
                                        } else if value.translation.width > 50 {
                                            selectedPlan = max(selectedPlan - 1, 0)
                                        }
                                    }
                                }
                        )
                        HStack(spacing: 8) {
                            ForEach(0 ..< 3) { i in
                                Circle()
                                    .fill(i == selectedPlan ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        enterpriseCard
                            .padding(.horizontal, 16)
                    }
                    if !isSubscribed {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 20))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, accentBlue)
                            Text("Secure Payment")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.4))
                            Text("•")
                                .foregroundColor(.white.opacity(0.2))
                            Text("Cancel Anytime")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.4))
                            Image(systemName: "percent")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(accentBlue)
                                .clipShape(Circle())
                        }
                        .padding(.top, 8)
                    }
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    if !isSubscribed {
                        Button {
                            Task { await restoreSubscription() }
                        } label: {
                            HStack {
                                if isRestoring {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Restore Subscription")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.55, green: 0.25, blue: 0.85), Color(red: 0.25, green: 0.47, blue: 0.95)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .disabled(isRestoring)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    if isSubscribed {
                        Button {
                            showCancelConfirmation = true
                        } label: {
                            HStack {
                                if isCanceling {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Cancel Subscription")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.red)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(cardBg)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(cardBorder, lineWidth: 1)
                                    )
                            )
                        }
                        .disabled(isCanceling)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    Spacer(minLength: 30)
                }
            }
            .scrollIndicators(.hidden)
            .disabled(isVerifying || isLoading || isLoadingPrices)
            .blur(radius: (isVerifying || isLoading || isLoadingPrices) ? 3 : 0)
            if isVerifying || isLoading || isLoadingPrices {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 14) {
                            ProgressView()
                                .scaleEffect(1.4)
                            Text("Loading...")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(28)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                    }
            }
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isPresentedAsSheet {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.leading, -4)
                    }
                } else {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.leading, 0)
                    }
                }
            }
        }
        .task {
            await verifySubscription()
            await fetchPrices()
        }
        .alert("Subscribed!", isPresented: $showSuccess) {
            Button("OK") {
                Task { await authState.restoreSession() }
            }
        } message: {
            Text("Welcome to \(planName)! Your subscription is now active.")
        }
        .alert("Cancel Subscription", isPresented: $showCancelConfirmation) {
            Button("Yes, Cancel", role: .destructive) {
                Task { await cancelSubscription() }
            }
            Button("Keep Plan", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel your active subscription? This action cannot be undone and your \(planName) benefits will be terminated.")
        }
    }

    private func toggleButton(title: String, isSelected: Bool, badge: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(colors: [accentBlue, Color(red: 0.55, green: 0.25, blue: 0.85)],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .overlay(isSelected ? Capsule().stroke(Color.white, lineWidth: 1) : nil)
                }
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                    Capsule().fill(accentBlue) :
                    Capsule().fill(Color.clear)
            )
        }
    }

    private var basicPlanCard: some View {
        VStack(spacing: 12) {
            Text("Basic")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("$")
                    .font(.system(size: 16, weight: .bold))
                Text(displayPrice(for: isYearly ? "basic_yearly" : "basic_monthly", fallback: isYearly ? "79" : "5.99"))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text(isYearly ? "/yr" : "/mo")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
            .foregroundColor(.white)
            Text("For Small Teams")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
            VStack(alignment: .leading, spacing: 8) {
                featureItem("Up to 50 Active Clients")
                featureItem("Standard Email Integration")
                featureItem("Basic Dashboard Insights")
            }
            .padding(.top, 4)
            Spacer()
            Button {
                Task {
                    await preparePaymentSheet(planId: isYearly ? "basic_yearly" : "basic_monthly")
                    if paymentSheet != nil {
                        isPaymentSheetPresented = true
                    }
                }
            } label: {
                Text("Select")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(cardBorder, lineWidth: 1)
                )
        )
    }

    private var proPlanCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Text("Most Popular")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                Image(systemName: "crown.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                LinearGradient(colors: [Color(red: 0.55, green: 0.25, blue: 0.85), accentBlue],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
            Text("Pro")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("$")
                    .font(.system(size: 16, weight: .bold))
                Text(displayPrice(for: isYearly ? "pro_yearly" : "pro_monthly", fallback: isYearly ? "159" : "199"))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text(isYearly ? "/yr" : "/mo")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
            .foregroundColor(.white)
            if isYearly {
                Text("Save 20%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.yellow)
                    .clipShape(Capsule())
                    .padding(.top, -2)
            }
            Text("For Growing Businesses")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
                .padding(.top, isYearly ? 4 : 0)
            VStack(alignment: .leading, spacing: 8) {
                featureItem("Unlimited Active Clients")
                featureItem("AI-Powered Email Polish ")
                featureItem("Advanced Client Filtering")
                featureItem("Priority Email Support")
            }
            .padding(.top, 4)
            Spacer()
            VStack {
                Button {
                    if paymentSheet != nil {
                        isPaymentSheetPresented = true
                    } else {
                        Task {
                            await preparePaymentSheet(planId: isYearly ? "pro_yearly" : "pro_monthly")
                            if paymentSheet != nil {
                                isPaymentSheetPresented = true
                            }
                        }
                    }
                } label: {
                    proSelectLabel
                }
                .disabled(isLoading)
            }
            .paymentSheet(
                isPresented: $isPaymentSheetPresented,
                paymentSheet: paymentSheet ?? PaymentSheet(paymentIntentClientSecret: "", configuration: PaymentSheet.Configuration()),
                onCompletion: handlePaymentResult
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(colors: [Color(red: 0.55, green: 0.25, blue: 0.85), accentBlue],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                )
        )
    }

    private var proSelectLabel: some View {
        HStack(spacing: 6) {
            Text("Select")
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8).fill(accentBlue)
        )
    }

    private var teamPlanCard: some View {
        VStack(spacing: 12) {
            Text("Team")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("$")
                    .font(.system(size: 16, weight: .bold))
                Text(displayPrice(for: isYearly ? "team_yearly" : "team_monthly", fallback: isYearly ? "239" : "299"))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text(isYearly ? "/yr" : "/mo")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
            .foregroundColor(.white)
            Text("For Larger Teams")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
            VStack(alignment: .leading, spacing: 8) {
                featureItem("Unlimited Active Clients")
                featureItem("AI-Powered Email Polish ")
                featureItem("Advanced Analytics")
                featureItem("Early Access to Features")
            }
            .padding(.top, 4)
            Spacer()
            Button {
                Task {
                    await preparePaymentSheet(planId: isYearly ? "team_yearly" : "team_monthly")
                    if paymentSheet != nil {
                        isPaymentSheetPresented = true
                    }
                }
            } label: {
                Text("Select")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(cardBorder, lineWidth: 1)
                )
        )
    }

    private var enterpriseCard: some View {
        VStack(spacing: 12) {
            Text("Enterprise")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text("Custom Pricing")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            VStack(alignment: .leading, spacing: 8) {
                featureItem("Custom Cloud Deployment")
                featureItem("Dedicated Server Instance")
                featureItem("Custom CRM Workflows")
            }
            .padding(.vertical, 4)
            Button {} label: {
                Text("Contact Us")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(cardBorder, lineWidth: 1)
                )
        )
        .padding(.top, 12)
    }

    private var activeSubscriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .green)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.70, green: 0.45, blue: 1.0), Color(red: 0.55, green: 0.78, blue: 1.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("\(planName) Plan Active")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    if let end = authState.currentUser?.current_period_end {
                        Text("Renews: \(formattedDate(end))")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
            }
            planFeatureChips
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(cardBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.top, 5)
    }

    private func featureItem(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.75))
        }
    }

    private func featureChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 9))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundColor(.white.opacity(0.6))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var planFeatureChips: some View {
        switch planName {
        case "Basic":
            HStack(spacing: 8) {
                featureChip(icon: "person.2.fill", text: "50 Clients")
                featureChip(icon: "envelope.fill", text: "Email")
                featureChip(icon: "chart.pie.fill", text: "Dashboard")
            }
        case "Team":
            HStack(spacing: 8) {
                featureChip(icon: "person.3.fill", text: "Unlimited")
                featureChip(icon: "chart.bar.fill", text: "Analytics")
                featureChip(icon: "star.fill", text: "Early Access")
            }
        default:
            HStack(spacing: 8) {
                featureChip(icon: "person.3.fill", text: "Unlimited")
                featureChip(icon: "sparkles", text: "AI Email")
                featureChip(icon: "line.3.horizontal.decrease", text: "Filtering")
            }
        }
    }

    private func offsetForCard(_ index: Int) -> CGFloat {
        let diff = index - selectedPlan
        return CGFloat(diff) * 160
    }

    private func formattedDate(_ isoString: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: isoString) {
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            fmt.timeStyle = .none
            return fmt.string(from: date)
        }
        let iso2 = ISO8601DateFormatter()
        if let date = iso2.date(from: isoString) {
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            fmt.timeStyle = .none
            return fmt.string(from: date)
        }
        return isoString
    }

    @MainActor
    private func verifySubscription() async {
        isVerifying = true
        do {
            let status = try await SubscriptionService.getStatus()
            if status.subscription_status == "active",
               authState.currentUser?.subscription_status != "active"
            {
                await authState.restoreSession()
            } else if status.subscription_status != "active",
                      authState.currentUser?.subscription_status == "active"
            {
                await authState.restoreSession()
            }
        } catch {}
        isVerifying = false
    }

    @MainActor
    private func restoreSubscription() async {
        isRestoring = true
        do {
            let status = try await SubscriptionService.getStatus()
            if status.subscription_status == "active" {
                await authState.restoreSession()
            }
        } catch {}
        isRestoring = false
    }

    @MainActor
    private func cancelSubscription() async {
        isCanceling = true
        errorMessage = nil
        do {
            let response = try await SubscriptionService.cancelSubscription()
            if response.success {
                await authState.restoreSession()
            } else {
                errorMessage = response.message
            }
        } catch {
            errorMessage = "Failed to cancel: \(error.localizedDescription)"
        }
        isCanceling = false
    }

    @MainActor
    private func fetchPrices() async {
        do {
            isLoadingPrices = true
            let response = try await SubscriptionService.getPrices()
            var newPrices: [String: String] = [:]
            for item in response.prices {
                newPrices[item.plan_id] = item.price_string
            }
            prices = newPrices
        } catch {}
        isLoadingPrices = false
    }

    private func displayPrice(for planId: String, fallback: String) -> String {
        if isLoadingPrices { return "..." }
        guard let priceStr = prices[planId] else { return fallback }
        return priceStr
    }

    @MainActor
    private func preparePaymentSheet(planId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await SubscriptionService.createPaymentIntent(planId: planId)
            STPAPIClient.shared.publishableKey = response.publishable_key
            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "ClientTrack CRM+"
            configuration.customer = .init(
                id: response.customer,
                ephemeralKeySecret: response.ephemeral_key
            )
            configuration.allowsDelayedPaymentMethods = false
            configuration.appearance.colors.background = UIColor(red: 0.11, green: 0.11, blue: 0.14, alpha: 1)
            configuration.appearance.colors.componentBackground = UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1)
            configuration.appearance.colors.primary = UIColor(red: 0.25, green: 0.47, blue: 0.95, alpha: 1)
            configuration.appearance.colors.text = .white
            configuration.appearance.colors.textSecondary = UIColor(white: 0.55, alpha: 1)
            configuration.appearance.cornerRadius = 14
            configuration.appearance.colors.componentBorder = .clear
            configuration.appearance.font.base = UIFont.systemFont(ofSize: 16)
            paymentSheet = PaymentSheet(
                paymentIntentClientSecret: response.payment_intent,
                configuration: configuration
            )
        } catch {
            errorMessage = "Failed to load checkout: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func handlePaymentResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            paymentSheet = nil
            Task {
                isVerifying = true
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await verifySubscription()
                await authState.restoreSession()
                isVerifying = false
                showSuccess = true
            }
        case .canceled:
            paymentSheet = nil
        case let .failed(error):
            errorMessage = error.localizedDescription
            paymentSheet = nil
        }
    }
}

#Preview {
    NavigationStack {
        SubscriptionView()
    }
    .environmentObject(AuthState())
}
