//
//  String+CacheBuster.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

extension String {
    func appendingCacheBuster(version: Int) -> String {
        if contains("?") {
            return self + "&v=\(version)"
        } else {
            return self + "?v=\(version)"
        }
    }
}
