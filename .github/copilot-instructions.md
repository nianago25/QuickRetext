# Copilot Instructions — QuickRetext

## プロジェクト概要

クリップボードのテキストをデバイス内AI（Apple Intelligence / Foundation Models）で「要約」または「リライト」する完全オフラインテキスト変換アプリ。

---

## 技術スタック

| 項目 | 値 |
|------|----|
| 言語 | Swift 6 |
| UI フレームワーク | SwiftUI |
| 最小ターゲット | iOS 26+ |
| データ永続化 | SwiftData |
| AI | Foundation Models（オンデバイス） |
| 広告 | Google AdMob（GADBannerView） |
| 課金 | StoreKit 2（Non-Consumable） |
| テストフレームワーク | Swift Testing（`@Test`, `#expect` 等） |

> **XCTest は使用しない。** テストはすべて Swift Testing で記述すること。

---

## アーキテクチャ

**MVVM（3層構造）**

```
View（SwiftUI）
  ↓
ViewModel（@MainActor, ObservableObject）
  ↓
Repository（Protocol で抽象化）
```

### 基本ルール

- **1 View — 1 ViewModel** の対応を厳守する
- ViewModel は `@MainActor final class` で `ObservableObject` に準拠する
- Repository はプロトコルで抽象化し、テスト時にモックへ差し替え可能にする
- DI は `AppDependencies`（`ObservableObject`）を `@EnvironmentObject` で注入する
- View は Repository を直接参照しない。必ず ViewModel を経由する
- 判断に迷った場合は.  doc/quick.md を参照すること

### 画面 — ViewModel 対応

| 画面 | ViewModel |
|------|-----------|
| MainView | MainViewModel |
| HistoryView | HistoryViewModel |
| SettingView | SettingViewModel |

### Repository 構成

| Repository | Protocol | 役割 |
|------------|----------|------|
| AIRepository | AIRepositoryProtocol | Foundation Models によるテキスト変換 |
| HistoryRepository | HistoryRepositoryProtocol | SwiftData による履歴 CRUD |

---

## ディレクトリ構成

```
QuickRetext/
├── QuickRetextApp.swift
├── App/
│   └── AppDependencies.swift
├── Models/
│   ├── Mode.swift
│   ├── LengthInstruction.swift
│   ├── ToneInstruction.swift
│   ├── LanguageInstruction.swift
│   └── HistoryItem.swift
├── Repositories/
│   ├── AIRepositoryProtocol.swift
│   ├── AIRepository.swift
│   ├── HistoryRepositoryProtocol.swift
│   └── HistoryRepository.swift
├── ViewModels/
│   ├── MainViewModel.swift
│   ├── HistoryViewModel.swift
│   └── SettingViewModel.swift
├── Views/
│   ├── MainView.swift
│   ├── HistoryView.swift
│   ├── SettingView.swift
│   └── Components/
│       ├── InputAreaView.swift
│       ├── OutputAreaView.swift
│       ├── ControlPanelView.swift
│       ├── HistoryRowView.swift
│       └── AdBannerView.swift
└── Utilities/
    └── LanguageDetector.swift
```

新規ファイルはこの構成に従って配置すること。

---

## コーディング規約

### 命名規則

| 対象 | スタイル | 例 |
|------|---------|-----|
| 型（class / struct / enum / protocol） | UpperCamelCase | `MainViewModel`, `AIRepositoryProtocol` |
| 変数・関数・プロパティ | lowerCamelCase | `inputText`, `loadClipboardIfNeeded()` |
| 定数（`let`） | lowerCamelCase | `let maxInputLength = 1500` |
| enum case | lowerCamelCase | `.summarize`, `.ultraShort` |
| Bool 型プロパティ | `is` / `has` / `can` / `should` プレフィックス | `isProcessing`, `canConvert`, `hasShownAlert` |
| Protocol 名 | 末尾に `Protocol` を付ける | `AIRepositoryProtocol` |
| ファイル名 | 型名と一致させる | `MainViewModel.swift` |

### アクセス修飾子

- **最小限の公開範囲**を原則とする
- 外部から参照不要なプロパティ・メソッドには `private` を付ける
- ViewModel の `@Published` プロパティは `private(set)` を検討する（外部から直接代入が必要な場合を除く）
- Repository の実装クラスには `final` を付ける
- ViewModel クラスには `final` を付ける

```swift
// Good
@MainActor
final class MainViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published private(set) var isProcessing: Bool = false
    private var currentTask: Task<Void, Never>?
    private let aiRepository: AIRepositoryProtocol
}

// Bad — アクセス修飾子なし
class MainViewModel: ObservableObject {
    var currentTask: Task<Void, Never>?
    var aiRepository: AIRepositoryProtocol
}
```

### Swift Concurrency

- ViewModel は `@MainActor` を付ける
- 非同期処理は `async/await` を使う（Combine は使わない）
- `Task` のキャンセルは `currentTask?.cancel()` で行う
- `CancellationError` はユーザーに表示しない

### コメント

- 「何をしているか」ではなく「なぜそうしているか」をコメントする
- 自明なコードにはコメントしない
- `// MARK: -` でセクションを区切る

---

## 禁止事項

### Force Unwrap（`!`）禁止

`!` による強制アンラップは原則禁止。`guard let` / `if let` / nil coalescing（`??`）を使う。

```swift
// ❌ 禁止
let text = UIPasteboard.general.string!

// ✅ OK
guard let text = UIPasteboard.general.string else { return }
```

**唯一の例外**: `ModelContainer` の生成は仕様上 `try!` を許可する（致命的エラーのため）。

```swift
let container = try! ModelContainer(for: HistoryItem.self)
```

### Force Cast（`as!`）禁止

```swift
// ❌ 禁止
let vc = storyboard.instantiateViewController(withIdentifier: "Main") as! MainViewController

// ✅ OK
guard let vc = storyboard.instantiateViewController(withIdentifier: "Main") as? MainViewController else { return }
```

### Implicitly Unwrapped Optional（`!` 宣言）禁止

```swift
// ❌ 禁止
var name: String!

// ✅ OK
var name: String?
var name: String = ""
```

### その他の禁止事項

| 禁止事項 | 理由 |
|---------|------|
| `Any` / `AnyObject` の多用 | 型安全性が損なわれるため |
| Storyboard / XIB の使用 | SwiftUI で統一するため |
| Combine の使用 | async/await に統一するため |
| `print()` をプロダクションコードに残す | デバッグ時のみ使用し、コミット前に削除する |
| ハードコードされた文字列リテラル（広告IDなど） | `Info.plist` または定数ファイルで管理する |
| View から Repository を直接呼び出す | 必ず ViewModel を経由する |
| `@ObservedObject` で ViewModel を View 内で生成する | `AppDependencies` 経由で注入する |
| TabView の使用 | NavigationStack による単方向ナビゲーションで統一する |

---

## テスト方針

### フレームワーク

**Swift Testing** を使用する。XCTest は使用しない。

```swift
import Testing

struct MainViewModelTests {
    @Test("空のテキストでは変換できない")
    func cannotConvertWithEmptyInput() async {
        let vm = MainViewModel(ai: MockAIRepository(), history: MockHistoryRepository(), isModelAvailable: true)
        #expect(vm.canConvert == false)
    }
}
```

### テスト対象

| レイヤー | テスト対象 | テスト内容 |
|---------|----------|-----------|
| ViewModel | MainViewModel | 状態遷移、変換制御、キャンセル処理 |
| ViewModel | HistoryViewModel | 履歴取得・削除・復元 |
| ViewModel | SettingViewModel | 設定の永続化、購入フロー |
| Model | LengthInstruction | ステップ値からの変換 |
| Model | ToneInstruction | ステップ値からの変換 |
| Utility | LanguageDetector | 言語判定ロジック |

### テスト用モック

- `AIRepositoryProtocol` → `MockAIRepository` を作成
- `HistoryRepositoryProtocol` → `MockHistoryRepository` を作成
- DI でプロトコルを注入する設計のため、モック差し替えが容易

---

## 主要な仕様サマリー

### 入力制限

- 最大 **1500 文字**（超過時は変換ボタン無効化、文字数カウントを赤字表示）
- 切り捨ては行わない

### AI 変換

- Foundation Models の `LanguageModelSession` を使用
- summarize: temperature 0.2 / rewrite: temperature 0.4
- 出力トークン上限: `GenerationOptions(maximumResponseTokens: 800)`
- 言語判定は先頭100文字で日本語/英語を自動判定

### モード

| モード | パラメータ | ステップ |
|--------|----------|---------|
| summarize | LengthInstruction | ultraShort / concise / balanced / detailed |
| rewrite | ToneInstruction | casual / polite / formal / business |

### エラーハンドリング

- `AIRepositoryError` で統一（`.modelUnavailable`, `.inputTooLong`, `.generationFailed`, `.unknown`）
- `CancellationError` はダイアログを表示しない
- モデル未対応端末はアプリ起動時にダイアログを表示し、変換機能を無効化する

### データ永続化

| データ | 方式 |
|--------|------|
| 変換履歴 | SwiftData（`HistoryItem`） |
| クリップボード自動読み込み設定 | UserDefaults |
| 広告削除購入状態 | StoreKit entitlements（UserDefaults に保存しない） |
