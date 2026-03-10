//
//  RootView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authState: AuthState
    var body: some View {
        switch authState.status {
        case .checkingSession:
            SplashView()
        case .authenticated:
            MainTabView()
        case .unauthenticated:
            LoginView()
        }
    }
}
