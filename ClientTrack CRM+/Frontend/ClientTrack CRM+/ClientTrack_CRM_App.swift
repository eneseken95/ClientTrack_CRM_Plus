//
//  ClientTrack_CRM_App.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

@main
struct ClientTrack_CRM_App: App {
    @StateObject private var authState = AuthState()
    init() {
        let backAppearance = UIBarButtonItemAppearance(style: .plain)
        backAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        backAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.clear]
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.backButtonAppearance = backAppearance
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterialDark)
        standardAppearance.backgroundColor = UIColor.clear
        standardAppearance.shadowColor = .clear
        standardAppearance.backButtonAppearance = backAppearance
        UINavigationBar.appearance().standardAppearance = standardAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
        UINavigationBar.appearance().compactAppearance = standardAppearance
        UINavigationBar.appearance().tintColor = .white
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authState)
                .preferredColorScheme(.dark)
                .tint(.white)
        }
    }
}
