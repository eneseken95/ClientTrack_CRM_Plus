//
//  TaskDTO.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 22.02.2026.
//

import Foundation

struct TaskDTO: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let description: String?
    let status: String
    let due_date: String?
    let client_id: Int
    let owner_id: Int
    let created_at: String
    let client_name: String?
    let client_logo: String?
    let client_company: String?
    let client_email: String?
    let client_category: String?
    let client_industry: String?
    let client_status: String?
}
