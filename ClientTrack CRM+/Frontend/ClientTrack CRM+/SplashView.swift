//
//  SplashView.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import SwiftUI

struct SplashView: View {
    @State private var pulse = false
    @State private var opacity: Double = 0
    var body: some View {
        ZStack {
            AppTheme.splashGradient
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .white.opacity(0.15), radius: 12, x: 0, y: 0)
                    .scaleEffect(pulse ? 1.06 : 0.96)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: pulse
                    )
                Text("ClientTrack CRM+")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                ProgressView()
                    .tint(.white.opacity(0.7))
                    .scaleEffect(0.9)
                Text("Checking session…")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .opacity(opacity)
        }
        .onAppear {
            pulse = true
            withAnimation(.easeIn(duration: 0.6)) {
                opacity = 1
            }
        }
    }
}
