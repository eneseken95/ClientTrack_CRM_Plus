//
//  AuthFlowModels.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

struct MessageDTO: Decodable {
    let message: String
}

struct RegisterRequestDTO: Encodable {
    let name: String
    let surname: String
    let email: String
    let phone: String
    let password: String
}

struct VerifyEmailRequestDTO: Encodable {
    let email: String
    let otp: String
}

struct ResendOTPRequestDTO: Encodable {
    let email: String
}

struct ForgotPasswordRequestDTO: Encodable {
    let email: String
}

struct ResetPasswordRequestDTO: Encodable {
    let email: String
    let otp: String
    let new_password: String
}
