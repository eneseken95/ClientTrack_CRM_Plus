//
//  UserRequests.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

struct UpdateUserRequestDTO: Encodable {
    let name: String
    let surname: String
    let phone: String?
}

struct ChangeEmailRequestDTO: Encodable {
    let new_email: String
}

struct OTPRequestDTO: Encodable {
    let otp: String
}
