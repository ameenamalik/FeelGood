//
//  FeelGoodApp.swift
//  FeelGood
//

import SwiftUI

@main
struct FeelGoodApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// Placeholder root. The SwiftData container and real routing land with the
/// persistence models; today this exists so the target builds while the
/// engine and content schema are going in.
struct RootView: View {
    var body: some View {
        Text("FeelGood")
            .font(.system(.largeTitle, design: .serif))
    }
}
