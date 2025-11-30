//
//  Word_ChainsApp.swift
//  Word_Chains
//
//  Created by Shane Maxfield on 4/27/25.
//

import SwiftUI

@main
struct Word_ChainsApp: App {
    @StateObject private var gameState = EnhancedGameState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    // Force persist when app backgrounds
                    gameState.forcePersist()
                }
        }
    }
}
