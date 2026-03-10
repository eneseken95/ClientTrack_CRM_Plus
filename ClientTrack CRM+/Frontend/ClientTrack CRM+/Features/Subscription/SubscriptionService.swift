//
//  SubscriptionService.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 23.02.2026.
//

import Foundation

struct PaymentIntentResponse: Decodable {
    let payment_intent: String
    let ephemeral_key: String
    let customer: String
    let publishable_key: String
}

struct SubscriptionStatusResponse: Decodable {
    let subscription_status: String
    let subscription_plan_id: String?
    let current_period_end: String?
}

struct SubscriptionPriceItem: Decodable {
    let plan_id: String
    let price_string: String
}

struct SubscriptionPricesResponse: Decodable {
    let prices: [SubscriptionPriceItem]
}

struct PaymentIntentRequest: Encodable {
    let plan_id: String
}

struct SubscriptionCancelResponse: Decodable {
    let success: Bool
    let message: String
}

enum SubscriptionService {
    static func createPaymentIntent(planId: String) async throws -> PaymentIntentResponse {
        let payload = PaymentIntentRequest(plan_id: planId)
        let body = try JSONCoding.encoder.encode(payload)
        return try await APIClient.shared.request(.createPaymentIntent(planId: planId), body: body)
    }

    static func getStatus() async throws -> SubscriptionStatusResponse {
        return try await APIClient.shared.request(.subscriptionStatus)
    }

    static func getPrices() async throws -> SubscriptionPricesResponse {
        return try await APIClient.shared.request(.subscriptionPrices)
    }

    static func cancelSubscription() async throws -> SubscriptionCancelResponse {
        return try await APIClient.shared.request(.cancelSubscription)
    }
}
