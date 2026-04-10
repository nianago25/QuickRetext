//
//  QuickRetextApp.swift
//  QuickRetext
//
//  Created by Yusuke Miyanaga on 2026/04/01.
//

import SwiftUI
import QuickRetext_Models
import QuickRetext_Repositories
import QuickRetext_ViewModels

@main
struct QuickRetextApp: App {
    @State private var deps = AppDependencies()
    /// isAdRemoved など複数画面で共有する状態を持つため App レベルで保持
    @StateObject private var settingViewModel = SettingViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainView(
                aiRepository: deps.aiRepository,
                historyRepository: deps.historyRepository,
                isModelAvailable: deps.isModelAvailable
            )
            .environmentObject(settingViewModel)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await settingViewModel.checkPurchaseStatus() }
        }
    }
}
