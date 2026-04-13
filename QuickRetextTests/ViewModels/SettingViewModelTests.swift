import Testing
@testable import QuickRetext_ViewModels

@Suite("SettingViewModel Tests")
@MainActor
struct SettingViewModelTests {

    @Test("初期状態では isAdRemoved が false")
    func initialIsAdRemovedFalse() {
        let vm = SettingViewModel()
        #expect(vm.isAdRemoved == false)
    }

    @Test("初期状態では isPurchasing が false")
    func initialIsPurchasingFalse() {
        let vm = SettingViewModel()
        #expect(vm.isPurchasing == false)
    }

    @Test("初期状態では isRestoring が false")
    func initialIsRestoringFalse() {
        let vm = SettingViewModel()
        #expect(vm.isRestoring == false)
    }

    @Test("初期状態では purchaseError が nil")
    func initialPurchaseErrorNil() {
        let vm = SettingViewModel()
        #expect(vm.purchaseError == nil)
    }

    @Test("製品 ID が正しい値である")
    func productIDIsCorrect() {
        #expect(SettingViewModel.productID == "com.github.nianago25.QuickRetext.removeAds")
    }
}
