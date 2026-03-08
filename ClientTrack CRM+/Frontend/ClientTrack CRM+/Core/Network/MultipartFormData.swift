//
//  MultipartFormData.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

struct MultipartFormData {
    let boundary: String
    private(set) var body = Data()
    init() {
        boundary = "Boundary-\(UUID().uuidString)"
    }

    mutating func addFile(
        fieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) {
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")
    }

    mutating func finalize() {
        body.append("--\(boundary)--\r\n")
    }

    var contentTypeHeader: String {
        "multipart/form-data; boundary=\(boundary)"
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
