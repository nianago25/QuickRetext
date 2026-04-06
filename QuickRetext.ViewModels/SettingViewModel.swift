import Combine
import StoreKit
import QuickRetext_Utilities

@MainActor
public final class SettingViewModel: ObservableObject {

    @Published public var isAdRemoved: Bool = false
    @Published public var isClipboardAutoLoadEnabled: Bool = UserDefaults.standard.isClipboardAutoLoadEnabled {
        didSet {
            UserDefaults.standard.isClipboardAutoLoadEnabled = isClipboardAutoLoadEnabled
        }
    }
    @Published public var isPurchasing: Bool = false

    private static let productID = "com.xxx.QuickRetext.removeAds"

    public init() {}

    // MARK: - Purchase Status

    public func checkPurchaseStatus() async {
        var found = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID {
                isAdRemoved = true
                found = true
                return
            }
        }
        if !found {
            isAdRemoved = false
        }
    }

    // MARK: - Purchase

    public func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let products = try await Product.products(for: [Self.productID])
            guard let product = products.first else { return }

            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified = verification {
                    isAdRemoved = true
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            // 購入エラーは isAdRemoved を変更しない
        }
    }

    // MARK: - Restore

    public func restore() async {
        do {
            try await AppStore.sync()
            await checkPurchaseStatus()
        } catch {
            // 復元エラーは無視
        }
    }
}
