//
//  PrometheusParser.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

struct MetricsData {
    var httpRequests: [HTTPRequestMetric] = []
    var systemMetrics: SystemMetrics?
}

struct HTTPRequestMetric: Identifiable {
    let id = UUID()
    let method: String
    let path: String
    let status: String
    let count: Double
}

struct SystemMetrics {
    var memoryUsage: Double = 0
    var cpuTime: Double = 0
    var openFDs: Double = 0
}

class PrometheusParser {
    static func parse(_ text: String) -> MetricsData {
        var data = MetricsData()
        var systemMetrics = SystemMetrics()
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            if trimmed.hasPrefix("http_requests_total{") {
                if let metric = parseHTTPRequest(trimmed) {
                    data.httpRequests.append(metric)
                }
            }
            if trimmed.hasPrefix("process_resident_memory_bytes ") {
                systemMetrics.memoryUsage = parseValue(trimmed)
            }
            if trimmed.hasPrefix("process_cpu_seconds_total ") {
                systemMetrics.cpuTime = parseValue(trimmed)
            }
            if trimmed.hasPrefix("process_open_fds ") {
                systemMetrics.openFDs = parseValue(trimmed)
            }
        }
        data.systemMetrics = systemMetrics
        return data
    }

    private static func parseHTTPRequest(_ line: String) -> HTTPRequestMetric? {
        guard let labelsStart = line.firstIndex(of: "{"),
              let labelsEnd = line.firstIndex(of: "}")
        else {
            return nil
        }
        let labelsString = String(line[line.index(after: labelsStart) ..< labelsEnd])
        let valueString = String(line[line.index(after: labelsEnd)...]).trimmingCharacters(in: .whitespaces)
        var method = ""
        var path = ""
        var status = ""
        let labels = labelsString.components(separatedBy: ",")
        for label in labels {
            let parts = label.components(separatedBy: "=")
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            switch key {
            case "method": method = value
            case "path": path = value
            case "status": status = value
            default: break
            }
        }
        guard let count = Double(valueString) else { return nil }
        return HTTPRequestMetric(method: method, path: path, status: status, count: count)
    }

    private static func parseValue(_ line: String) -> Double {
        let parts = line.components(separatedBy: " ")
        guard parts.count >= 2,
              let value = Double(parts.last ?? "0")
        else {
            return 0
        }
        return value
    }
}
