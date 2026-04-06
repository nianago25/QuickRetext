import SwiftUI

struct SettingView: View {
    @EnvironmentObject private var settingViewModel: SettingViewModel
    @State private var isCreditsExpanded = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    var body: some View {
        List {
            // MARK: - クリップボード自動読み込み
            Section {
                Toggle("クリップボード自動読み込み", isOn: $settingViewModel.isClipboardAutoLoadEnabled)
            }

            // MARK: - 広告・課金
            Section {
                purchaseRow
                if !settingViewModel.isAdRemoved {
                    Button("購入を復元する") {
                        Task { await settingViewModel.restore() }
                    }
                }
            }

            // MARK: - アプリ情報
            Section {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - クレジット
            Section {
                Button {
                    withAnimation { isCreditsExpanded.toggle() }
                } label: {
                    HStack {
                        Text("クレジット")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: isCreditsExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)

                if isCreditsExpanded {
                    creditsContent
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            AdBannerView(isVisible: !settingViewModel.isAdRemoved)
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Purchase Row

    @ViewBuilder
    private var purchaseRow: some View {
        if settingViewModel.isAdRemoved {
            HStack {
                Text("広告を非表示にする")
                Spacer()
                Text("購入済み")
                    .foregroundStyle(.secondary)
            }
        } else if settingViewModel.isPurchasing {
            HStack {
                Text("広告を非表示にする")
                Spacer()
                ProgressView()
            }
        } else {
            Button("広告を非表示にする") {
                Task { await settingViewModel.purchase() }
            }
        }
    }

    // MARK: - Credits

    private var creditsContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            creditRow(name: "Foundation Models", usage: "オンデバイスAI推論")
            creditRow(name: "SwiftData", usage: "履歴データ永続化")
            creditRow(name: "Google Mobile Ads SDK（AdMob）", usage: "バナー広告表示")
            creditRow(name: "StoreKit 2", usage: "アプリ内課金")
        }
        .padding(.vertical, 4)
    }

    private func creditRow(name: String, usage: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.subheadline)
            Text(usage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
