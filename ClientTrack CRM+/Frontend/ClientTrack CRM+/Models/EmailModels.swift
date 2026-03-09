//
//  EmailModels.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

struct EmailDTO: Codable, Identifiable {
    let id: Int
    let subject: String
    let body: String
    let sender: String
    let recipient: String
    let sentAt: String
    let isRead: Bool
    let clientName: String?
    let clientCompanyLogo: String?
}
