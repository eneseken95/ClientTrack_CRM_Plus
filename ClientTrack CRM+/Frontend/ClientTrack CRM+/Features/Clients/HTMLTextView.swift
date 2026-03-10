//
//  HTMLTextView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI
import WebKit

struct HTMLTextView: View {
    let htmlString: String
    @State private var contentHeight: CGFloat = 200
    var body: some View {
        WebView(htmlString: htmlString, contentHeight: $contentHeight)
            .frame(height: contentHeight)
    }
}

private struct WebView: UIViewRepresentable {
    let htmlString: String
    @Binding var contentHeight: CGFloat
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context _: Context) {
        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    font-size: 16px;
                    line-height: 1.5;
                    padding: 0;
                    margin: 0;
                    color: #000;
                }
                @media (prefers-color-scheme: dark) {
                    body { color: #fff; }
                }
            </style>
        </head>
        <body>
            \(htmlString)
        </body>
        </html>
        """
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { result, _ in
                if let height = result as? CGFloat {
                    DispatchQueue.main.async {
                        self.parent.contentHeight = height + 20
                    }
                }
            }
        }
    }
}
