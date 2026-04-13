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
import AppTrackingTransparency

#if canImport(GoogleMobileAds)
import GoogleMobileAds

/// AdMob SDK をアプリ起動直後に初期化する。
/// `start()` はバナー広告の `load()` より前に呼ぶ必要があるため AppDelegate で行う。
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if DEBUG
        // テスト端末で実際の広告リクエストが発生しないようにする
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["18cf2cf4501848a6068bcd2e5c25bcd5"]
        #endif
        MobileAds.shared.start(completionHandler: nil)
        return true
    }
}
#endif

@main
struct QuickRetextApp: App {
    #if canImport(GoogleMobileAds)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

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
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                requestTrackingAuthorization()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await settingViewModel.checkPurchaseStatus() }
        }
    }

    // MARK: - ATT

    /// ATT ダイアログは UIApplication が active 状態でないと表示できないため
    /// didBecomeActiveNotification で呼び出す。
    /// SDK の start() は AppDelegate で先に実施済み。
    private func requestTrackingAuthorization() {
        ATTrackingManager.requestTrackingAuthorization(completionHandler: { _ in })
    }

}
