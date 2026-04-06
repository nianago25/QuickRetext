//
//  QuickRetextApp.swift
//  QuickRetext
//
//  Created by Yusuke Miyanaga on 2026/04/01.
//

import SwiftUI

@main
struct QuickRetextApp: App {
    @State private var deps = AppDependencies()
    /// isAdRemoved など複数画面で共有する状態を持つため App レベルで保持
    @StateObject private var settingViewModel = SettingViewModel()
    @Environment(\.scenePhase) private var scenePhase

    /// ユニットテスト実行中かどうかを判定する。
    /// テストホストとしてアプリが起動すると UIPasteboard へのアクセスで
    /// OS のペースト許可ダイアログが表示されテストがハングするため、
    /// ユニットテスト時はアプリ UI を表示しない。
    private var isTesting: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    var body: some Scene {
        WindowGroup {
            if isTesting {
                Color.clear
            } else {
                MainView(
                    aiRepository: deps.aiRepository,
                    historyRepository: deps.historyRepository,
                    isModelAvailable: deps.isModelAvailable
                )
                .environmentObject(settingViewModel)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active, !isTesting else { return }
            Task { await settingViewModel.checkPurchaseStatus() }
        }
    }
}
