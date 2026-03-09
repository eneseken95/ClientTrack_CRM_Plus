//
//  AttachmentModels.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

struct AttachmentDTO: Codable, Identifiable {
    let id: Int
    let fileName: String
    let fileSize: Int
    let fileUrl: String
    let uploadedAt: String
    let path: String
}

struct DeleteAttachmentRequest: Codable {
    let path: String
}
