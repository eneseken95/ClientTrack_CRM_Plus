//
//  Endpoint.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

enum Endpoint {
    case register, verifyEmail, resendOTP, login, refresh, forgotPassword, resetPassword
    case me
    case updateMe
    case uploadAvatar
    case deleteAvatar
    case changeEmail
    case verifyEmailChange
    case deleteRequest
    case verifyDelete
    case clients(page: Int, size: Int)
    case createClient
    case patchClient(id: Int)
    case deleteClient(id: Int)
    case clientEmails(id: Int)
    case uploadCompanyLogo(id: Int)
    case getCompanyLogo(id: Int)
    case deleteCompanyLogo(id: Int)
    case uploadAttachment(clientId: Int)
    case listAttachments(clientId: Int)
    case deleteAttachment(clientId: Int)
    case tasks
    case tasksByClient(clientId: Int)
    case createTask
    case patchTask(id: Int)
    case deleteTask(id: Int)
    case listEmails
    case aiPolish
    case sendAIEmail
    case sendEmail
    case deleteEmail(id: Int)
    case searchClients(q: String)
    case adminListUsers
    case adminGetUserClients(userId: Int, page: Int, size: Int)
    case adminDeleteUser(userId: Int)
    case createPaymentIntent(planId: String)
    case subscriptionStatus
    case subscriptionPrices
    case cancelSubscription
    var method: String {
        switch self {
        case .register, .verifyEmail, .resendOTP, .login, .refresh, .forgotPassword, .resetPassword:
            return "POST"
        case .changeEmail, .verifyEmailChange, .deleteRequest, .verifyDelete:
            return "POST"
        case .createClient, .createTask, .aiPolish, .sendAIEmail, .sendEmail:
            return "POST"
        case .createPaymentIntent, .cancelSubscription:
            return "POST"
        case .uploadAttachment, .deleteAttachment:
            return "POST"
        case .updateMe, .uploadAvatar, .uploadCompanyLogo:
            return "PUT"
        case .patchClient, .patchTask:
            return "PATCH"
        case .deleteClient, .deleteAvatar, .deleteCompanyLogo, .deleteTask, .deleteEmail:
            return "DELETE"
        case .adminDeleteUser:
            return "DELETE"
        default:
            return "GET"
        }
    }

    var path: String {
        switch self {
        case .register: return "/auth/register"
        case .verifyEmail: return "/auth/verify-email"
        case .resendOTP: return "/auth/resend-otp"
        case .login: return "/auth/login"
        case .refresh: return "/auth/refresh"
        case .forgotPassword: return "/auth/forgot-password"
        case .resetPassword: return "/auth/reset-password"
        case .me, .updateMe: return "/users/me"
        case .uploadAvatar: return "/users/me/avatar"
        case .deleteAvatar: return "/users/me/avatar"
        case .changeEmail: return "/users/me/change-email"
        case .verifyEmailChange: return "/users/me/verify-email-change"
        case .deleteRequest: return "/users/me/delete-request"
        case .verifyDelete: return "/users/me/verify-delete"
        case .clients: return "/clients/"
        case .createClient: return "/clients/"
        case let .patchClient(id): return "/clients/patch/\(id)"
        case let .deleteClient(id): return "/clients/\(id)"
        case let .clientEmails(id): return "/clients/\(id)/emails"
        case let .uploadCompanyLogo(id): return "/clients/\(id)/company-logo"
        case let .getCompanyLogo(id): return "/clients/\(id)/logo"
        case let .deleteCompanyLogo(id): return "/clients/\(id)/logo"
        case let .uploadAttachment(clientId): return "/clients/\(clientId)/upload"
        case let .listAttachments(clientId): return "/clients/\(clientId)/attachments"
        case let .deleteAttachment(clientId): return "/clients/\(clientId)/attachments/delete"
        case .tasks: return "/tasks"
        case let .tasksByClient(clientId): return "/tasks/client/\(clientId)"
        case .createTask: return "/tasks"
        case let .patchTask(id): return "/tasks/\(id)"
        case let .deleteTask(id): return "/tasks/\(id)"
        case .listEmails: return "/emails/"
        case .aiPolish: return "/emails/ai-polish"
        case .sendAIEmail: return "/emails/send-ai"
        case .sendEmail: return "/emails/send"
        case let .deleteEmail(id): return "/emails/\(id)"
        case .searchClients: return "/search/clients"
        case .adminListUsers: return "/admin/users"
        case let .adminGetUserClients(userId, _, _): return "/admin/user/\(userId)"
        case let .adminDeleteUser(userId): return "/admin/users/\(userId)"
        case .createPaymentIntent: return "/subscriptions/create-payment-intent"
        case .subscriptionStatus: return "/subscriptions/status"
        case .subscriptionPrices: return "/subscriptions/prices"
        case .cancelSubscription: return "/subscriptions/cancel"
        }
    }

    func url() -> URL {
        switch self {
        case let .clients(page, size):
            var c = URLComponents(url: AppConfig.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
            c.queryItems = [
                .init(name: "page", value: "\(page)"),
                .init(name: "size", value: "\(size)"),
            ]
            return c.url!
        case let .searchClients(q):
            var c = URLComponents(url: AppConfig.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
            c.queryItems = [.init(name: "q", value: q)]
            return c.url!
        case let .adminGetUserClients(_, page, size):
            var c = URLComponents(url: AppConfig.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
            c.queryItems = [
                .init(name: "page", value: "\(page)"),
                .init(name: "size", value: "\(size)"),
            ]
            return c.url!
        default:
            return AppConfig.baseURL.appendingPathComponent(path)
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .register, .verifyEmail, .resendOTP, .login, .refresh, .forgotPassword, .resetPassword:
            return false
        default:
            return true
        }
    }
}
