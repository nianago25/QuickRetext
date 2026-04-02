import SwiftUI

// GoogleMobileAds SDK を SPM で追加後にコメントアウトを外す:
// File > Add Package Dependencies > https://github.com/googleads/swift-package-manager-google-mobile-ads
#if canImport(GoogleMobileAds)
import GoogleMobileAds

struct AdBannerView: UIViewRepresentable {
    var isVisible: Bool

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        let adUnitID = Bundle.main.object(forInfoDictionaryKey: "AdUnitID") as? String
            ?? "ca-app-pub-3940256099942544/2934735716" // テスト用フォールバック
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        uiView.isHidden = !isVisible
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: BannerView, context: Context) -> CGSize? {
        guard isVisible else { return CGSize(width: proposal.width ?? 320, height: 0) }
        return CGSize(width: proposal.width ?? 320, height: AdSizeBanner.size.height)
    }
}

#else

// AdMob SDK 未追加時のスタブ（SPM 追加後に上の実装が有効になる）
struct AdBannerView: View {
    var isVisible: Bool
    var body: some View {
        if isVisible {
            Color.gray.opacity(0.2)
                .frame(height: 50)
                .overlay(Text("Ad Placeholder").font(.caption).foregroundStyle(.secondary))
        }
    }
}

#endif
