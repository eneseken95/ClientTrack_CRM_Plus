//
//  AuthRoute.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

enum AuthRoute: Hashable {
    case register
    case verifyEmail(email: String)
    case forgotPassword
    case resetPassword(email: String)
}
