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
    @Published public var isRestoring: Bool = false
    @Published public var purchaseError: String? = nil

    public static let productID = "com.github.nianago25.QuickRetext.removeAds"

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
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let products = try await Product.products(for: [Self.productID])
            guard let product = products.first else {
                purchaseError = "製品情報を取得できませんでした"
                return
            }

            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    isAdRemoved = true
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = "購入できませんでした。もう一度お試しください"
        }
    }

    // MARK: - Restore

    public func restore() async {
        isRestoring = true
        purchaseError = nil
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
            await checkPurchaseStatus()
        } catch {
            purchaseError = "購入の復元に失敗しました。もう一度お試しください"
        }
    }
}
