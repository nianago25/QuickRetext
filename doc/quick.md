# クイックリテキスト 仕様書 v1.0（確定版）

ローカルAI（Apple Intelligence / Foundation Models）を使用した
完全オフライン要約・リライトアプリ

---

# 0. プロジェクト基本情報

| 項目 | 値 |
|------|----|
| アプリ名 | クイックリテキスト |
| Xcodeプロジェクト名 | QuickRetext |
| バンドルID | com.xxx.QuickRetext |
| ターゲット | iPhone / iPad（Universal） |
| 最小iOS | iOS 18.4以上（Foundation Models要件） |
| 言語 | Swift 6 |
| UI | SwiftUI |
| データ | SwiftData |
| 広告 | Google AdMob（GADBannerView） |
| 課金 | StoreKit 2（買い切り・nonConsumable） |

---

# 0-1. 画面一覧

| 画面 | ViewModel | 概要 |
|------|-----------|------|
| MainView | MainViewModel | メイン変換画面 |
| HistoryView | HistoryViewModel | 変換履歴一覧 |
| SettingView | SettingViewModel | 設定・バージョン・購入・クレジット |

※ CreditsView は作成しない。Setting画面内のクレジットセルをタップするとアコーディオンで展開する。

---

# 0-2. ディレクトリ構成

1View-1ViewModel の対応を基本とする。

```
QuickRetext/
├── QuickRetextApp.swift              // @main エントリーポイント
├── App/
│   └── AppDependencies.swift         // Repository初期化・DI
├── Models/
│   ├── Mode.swift                    // enum Mode { summarize, rewrite }
│   ├── LengthInstruction.swift       // enum LengthInstruction
│   ├── ToneInstruction.swift         // enum ToneInstruction
│   ├── LanguageInstruction.swift     // enum LanguageInstruction
│   └── HistoryItem.swift             // SwiftData @Model
├── Repositories/
│   ├── AIRepositoryProtocol.swift
│   ├── AIRepository.swift
│   ├── HistoryRepositoryProtocol.swift
│   └── HistoryRepository.swift
├── ViewModels/
│   ├── MainViewModel.swift           // MainView に対応
│   ├── HistoryViewModel.swift        // HistoryView に対応
│   └── SettingViewModel.swift        // SettingView に対応
├── Views/
│   ├── MainView.swift
│   ├── HistoryView.swift
│   ├── SettingView.swift
│   └── Components/
│       ├── InputAreaView.swift
│       ├── OutputAreaView.swift
│       ├── ControlPanelView.swift    // 下部固定エリア（変換ボタン・モード切替）
│       ├── HistoryRowView.swift
│       └── AdBannerView.swift        // UIViewRepresentable
└── Utilities/
    └── LanguageDetector.swift
```

---

# 0-3. Setting画面仕様

## 表示項目

- クリップボード自動読み込み（ON/OFF トグル）
- 広告を非表示にする（買い切り購入ボタン）
- 購入を復元する（Restoreボタン）
- アプリバージョン（表示のみ。Bundle version を自動取得）
- クレジット（タップでアコーディオン展開）

## クレジット展開内容

| ライブラリ / フレームワーク | 用途 |
|----------------------------|------|
| Foundation Models | オンデバイスAI推論 |
| SwiftData | 履歴データ永続化 |
| Google Mobile Ads SDK（AdMob） | バナー広告表示 |
| StoreKit 2 | アプリ内課金 |

## 課金仕様（StoreKit 2）

- 商品タイプ：Non-Consumable（買い切り）
- Product ID：`com.xxx.QuickRetext.removeAds`
- 購入済み判定：`Transaction.currentEntitlements` で確認
- 購入済みの場合：AdBannerView を非表示にし、「広告を非表示にする」ボタンを「購入済み」テキストに差し替える
- 復元ボタン：`AppStore.sync()` を呼び出す

### 購入ボタンのUI挙動

| 状態 | 表示 |
|------|------|
| 未購入 | 「広告を非表示にする」ボタン（タップで `settingViewModel.purchase()` 呼び出し） |
| 購入処理中 | ProgressView（`isPurchasing == true`） |
| 購入済み | 「購入済み」テキスト（グレー表示、タップ不可） |

### 復元ボタンのUI挙動

- 未購入時のみ表示
- タップで `settingViewModel.restore()` を呼び出す

## 永続化

- `isClipboardAutoLoadEnabled`：UserDefaults に保存
- 購入済み状態：StoreKit の entitlements で管理（UserDefaultsに保存しない）

---

# 1. アプリ概要

## コンセプト

クリップボードのテキストを即座に読み込み、
デバイス内AIで「要約」または「リライト」し、
ワンタップでコピーできる爆速テキスト変換ツール。

---

## 特徴

- 完全オフライン（Foundation Models使用）
- データはデバイス外に送信しない
- ダウンロードサイズ最小（OS内モデル利用）
- 広告あり（AdViewをView層に配置）
- サーバー不要
- ログイン不要

---

# 2. 技術構成

## アーキテクチャ

MVVM（3層構造）

View（SwiftUI）  
↓  
ViewModel  
↓  
Repository  

---

## Repository構成

- AIRepository
- HistoryRepository

---

## プロトコル

- AIRepositoryProtocol
- HistoryRepositoryProtocol

---

# 3. モデル生成戦略

## 方針

- AIRepository初期化時にLanguageModelを1回生成
- セッション毎に生成しない

```swift
final class AIRepository {
    private let model: LanguageModel

    init() throws {
        self.model = LanguageModel()
    }
}
```

> **注意**: 上記の `LanguageModel()` は概念的なコードであり、実際の Foundation Models API（`@available(iOS 26.0, *)` で提供予定）のシグネチャに合わせて調整すること。`SystemLanguageModel.default` や `LanguageModelSession` の生成方法が異なる場合は、同等の役割を果たすAPIに読み替える。

## AIRepository 実装イメージ

```swift
final class AIRepository: AIRepositoryProtocol {
    private let model: LanguageModel

    init() throws {
        self.model = LanguageModel()
    }

    func summarize(
        input: String,
        length: LengthInstruction,
        language: LanguageInstruction
    ) async throws -> String {
        let systemPrompt = """
        あなたはテキスト要約の専門家です。
        ユーザーが入力したテキストを、指示に従って要約します。
        - 出力は要約結果のみとし、前置き・説明・コメントは一切含めない
        - 元の意味・ニュアンスを正確に保つ
        - 内容に応じて箇条書きと文章を使い分けてよい
        """

        let userPrompt = """
        以下のテキストを要約してください。

        \(language.instruction)
        \(length.instruction)

        テキスト:
        \(input)
        """

        let session = LanguageModelSession(model: model, instructions: systemPrompt)
        let options = GenerationOptions(
            maximumResponseTokens: 800,
            temperature: 0.2
        )
        let response = try await session.respond(to: userPrompt, options: options)
        return response.content
    }

    func rewrite(
        input: String,
        tone: ToneInstruction,
        language: LanguageInstruction
    ) async throws -> String {
        let systemPrompt = """
        あなたはテキストリライトの専門家です。
        ユーザーが入力したテキストを、指定されたトーンで書き直します。
        - 出力はリライト結果のみとし、前置き・説明・コメントは一切含めない
        - 意味は保持しつつ、読みやすさを最優先する
        - 内容に応じて箇条書きと文章を使い分けてよい
        """

        let userPrompt = """
        以下のテキストを書き直してください。

        \(language.instruction)
        \(tone.instruction)

        テキスト:
        \(input)
        """

        let session = LanguageModelSession(model: model, instructions: systemPrompt)
        let options = GenerationOptions(
            maximumResponseTokens: 800,
            temperature: 0.4
        )
        let response = try await session.respond(to: userPrompt, options: options)
        return response.content
    }
}
```

> **補足**: `LanguageDetector.detect(input)` の呼び出しは各メソッドの冒頭で行い、結果を `language` 引数として受け取る設計。呼び出し元（MainViewModel の `convert()`）で `LanguageDetector.detect(inputText)` を実行して渡す。

---

# 4. プロンプト仕様

## 設計方針

- Foundation Models の `LanguageModelSession` を使用し、システムプロンプトで役割を固定する
- ユーザープロンプトに入力テキストと変換指示を渡す
- 言語・Length・Tone はすべて自然言語に変換してプロンプトに埋め込む
- 数値をそのままプロンプトに渡さない

---

## 言語指示の変換

| 判定結果 | プロンプトへの埋め込み文 |
|----------|--------------------------|
| 日本語 | `必ず日本語で出力してください。` |
| 英語 | `Output in English only.` |

---

## Length指示の変換

| LengthInstruction | プロンプトへの埋め込み文 |
|-------------------|--------------------------|
| ultraShort | `できるだけ短く、1〜2文で答えてください。` |
| concise | `要点のみを簡潔にまとめてください。` |
| balanced | `重要な情報を残しながら適切な長さにまとめてください。` |
| detailed | `情報をできるだけ保持しながら、読みやすくまとめてください。` |

---

## Tone指示の変換（rewrite専用）

| Tone（表示ラベル） | プロンプトへの埋め込み文 |
|------|--------------------------|
| カジュアル | `フレンドリーでカジュアルな口調で書いてください。` |
| 普通 | `やや丁寧で読みやすい口調で書いてください。` |
| 丁寧 | `丁寧で誠実な口調で書いてください。` |
| ビジネス | `ビジネス文書として適切なフォーマルな口調で書いてください。` |

---

## summarize プロンプトテンプレート

### システムプロンプト

```
あなたはテキスト要約の専門家です。
ユーザーが入力したテキストを、指示に従って要約します。
- 出力は要約結果のみとし、前置き・説明・コメントは一切含めない
- 元の意味・ニュアンスを正確に保つ
- 内容に応じて箇条書きと文章を使い分けてよい
```

### ユーザープロンプト

```
以下のテキストを要約してください。

{language_instruction}
{length_instruction}

テキスト:
{input_text}
```

### 埋め込み例（日本語 / balanced / なし）

```
以下のテキストを要約してください。

必ず日本語で出力してください。
重要な情報を残しながら適切な長さにまとめてください。

テキスト:
{input_text}
```

---

## rewrite プロンプトテンプレート

### システムプロンプト

```
あなたはテキストリライトの専門家です。
ユーザーが入力したテキストを、指定されたトーンで書き直します。
- 出力はリライト結果のみとし、前置き・説明・コメントは一切含めない
- 意味は保持しつつ、読みやすさを最優先する
- 内容に応じて箇条書きと文章を使い分けてよい
```

### ユーザープロンプト

```
以下のテキストを書き直してください。

{language_instruction}
{tone_instruction}

テキスト:
{input_text}
```

### 埋め込み例（日本語 / ビジネス）

```
以下のテキストを書き直してください。

必ず日本語で出力してください。
ビジネス文書として適切なフォーマルな口調で書いてください。

テキスト:
{input_text}
```

---

## Swift実装イメージ

```swift
func buildSummarizePrompt(
    input: String,
    length: LengthInstruction,
    language: LanguageInstruction
) -> String {
    """
    以下のテキストを要約してください。

    \(language.instruction)
    \(length.instruction)

    テキスト:
    \(input)
    """
}

func buildRewritePrompt(
    input: String,
    tone: ToneInstruction,
    language: LanguageInstruction
) -> String {
    """
    以下のテキストを書き直してください。

    \(language.instruction)
    \(tone.instruction)

    テキスト:
    \(input)
    """
}
```

システムプロンプトは `LanguageModelSession` の初期化時に渡す。

```swift
let session = LanguageModelSession(
    model: model,
    instructions: systemPrompt
)
```

---

# 5. AI仕様

## モード

- summarize
- rewrite

メソッドは分離する。

## Temperature

| モード | temperature |
|--------|-------------|
| summarize | 0.2 |
| rewrite | 0.4 |

topPは使用しない

## トークン設計

Foundation Models制限：4096トークン（入力＋出力の合計）

日本語は1文字あたり約1〜2トークンを消費するため、入力2500文字では最大5000トークンになり上限を超える恐れがある。
そのため入力上限を **1500文字** に設定し、出力に十分なトークンを確保する。

| 区分 | 設計値 | トークン目安 |
|------|--------|-------------|
| システムプロンプト | 固定 | 〜150トークン |
| ユーザープロンプト（指示文） | 固定 | 〜50トークン |
| 入力テキスト上限 | 1500文字 | 〜1500〜3000トークン |
| 出力トークン上限 | 800トークン | 〜400〜800文字 |
| 合計（最大） | — | 〜4000トークン（余裕あり） |

出力トークン上限は `GenerationOptions` でAPIレベルで指定する。

```swift
let options = GenerationOptions(maximumResponseTokens: 800)
let response = try await session.respond(to: prompt, options: options)
```

## 出力仕様

- 箇条書き固定しない
- 自然な文章で出力
- 入力言語と同じ言語で出力

---

# 6. 言語判定仕様

## 判定方法

- 入力テキスト先頭100文字を対象
- 50%以上が日本語なら日本語
- それ以外は英語扱い

## LanguageDetector 定義

```swift
enum LanguageDetector {
    static func detect(_ text: String) -> LanguageInstruction {
        let sample = String(text.prefix(100))
        let japaneseCount = sample.unicodeScalars.filter {
            ($0.value >= 0x3040 && $0.value <= 0x309F) ||  // ひらがな
            ($0.value >= 0x30A0 && $0.value <= 0x30FF) ||  // カタカナ
            ($0.value >= 0x4E00 && $0.value <= 0x9FFF)     // 漢字
        }.count
        return Double(japaneseCount) / Double(max(sample.count, 1)) >= 0.5
            ? .japanese : .english
    }
}
```

## 使用場所

`AIRepository` の `summarize` / `rewrite` 内で呼び出す。

```swift
let language = LanguageDetector.detect(input)
```

---

# 7. Length仕様（summarize専用・4段階ボタン）

## UI

画面下部固定エリアに配置する4つの `Button` で実装する。**summarize モード時のみ表示する。rewrite 時は非表示。**

- タップすると即座に `convert(lengthStep:)` を呼び出して変換実行する
- `lastExecutedLengthStep` と一致するボタンに下線を表示し「前回の実行粒度」を示す
- 処理中（`isProcessing == true`）の場合はキャンセルボタンに切り替わり非表示になる
- `canConvert == false`（入力空・1500文字超過・モデル未対応）の場合は `.disabled(true)` で表示

```swift
// summarize モード・通常時
HStack {
    ForEach(0..<4) { step in
        Button(LengthInstruction.label(for: step)) {
            viewModel.convert(lengthStep: step)
        }
        .underline(viewModel.lastExecutedLengthStep == step)
    }
}
```

## ステップ値と表示ラベルの対応

| lengthStep | LengthInstruction | 表示ラベル |
|-----------|-------------------|-----------|
| 0 | ultraShort | 短く |
| 1 | concise | 簡潔 |
| 2 | balanced | 標準 |
| 3 | detailed | 詳しく |

## LengthInstruction への変換

```swift
static func from(_ step: Int) -> LengthInstruction {
    switch step {
    case 0:  return .ultraShort
    case 1:  return .concise
    case 2:  return .balanced
    case 3:  return .detailed
    default: return .ultraShort
    }
}
```

## ViewModel の状態変数

```swift
@Published var lengthStep: Int = 0  // デフォルト：ultraShort（短く）
```

内部的には `LengthInstruction.from(lengthStep)` で変換して Repository に渡す（型定義は16章参照）。

---

# 8. Tone仕様（rewrite専用・4段階ボタン）

## UI

画面下部固定エリアに配置する4つの `Button` で実装する。**rewrite モード時のみ表示する。summarize 時は非表示。**

- タップすると即座に `convert(toneStep:)` を呼び出して変換実行する
- `lastExecutedToneStep` と一致するボタンに下線を表示し「前回の実行トーン」を示す
- 処理中（`isProcessing == true`）の場合はキャンセルボタンに切り替わり非表示になる
- `canConvert == false`（入力空・1500文字超過・モデル未対応）の場合は `.disabled(true)` で表示

```swift
// rewrite モード・通常時
HStack {
    ForEach(0..<4) { step in
        Button(ToneInstruction.label(for: step)) {
            viewModel.convert(toneStep: step)
        }
        .underline(viewModel.lastExecutedToneStep == step)
    }
}
```

## ステップ値と表示ラベルの対応

| toneStep | ToneInstruction | 表示ラベル |
|---------|-----------------|-----------|
| 0 | casual | カジュアル |
| 1 | polite | 普通 |
| 2 | formal | 丁寧 |
| 3 | business | ビジネス |

## ToneInstruction への変換

```swift
static func from(_ step: Int) -> ToneInstruction {
    switch step {
    case 0:  return .casual
    case 1:  return .polite
    case 2:  return .formal
    case 3:  return .business
    default: return .casual
    }
}
```

## ViewModel の状態変数

```swift
@Published var toneStep: Int = 2  // デフォルト：formal（丁寧）
```

数値を直接プロンプトに渡さず、`ToneInstruction.from(toneStep)` で自然言語へ変換する（型定義は16章参照）。

---

# 9. UI仕様

## レイアウト

```
┌─────────────────────────────────┐
│ 入力テキストエリア                │  ← スクロール内
├─────────────────────────────────┤
│ 簡潔（左寄せ、出力済み時のみ表示）│  ← lastExecuted の表示ラベル
├─────────────────────────────────┤
│ 出力テキストエリア                │  ← スクロール内
├─────────────────────────────────┤  ← safeAreaInset(edge: .bottom) で固定
│              [ 要約 | リライト ]  │  ← 右寄せ（isProcessing時は非表示）
│ [ 短く | 簡潔 | 標準 | 詳しく ]  │  ← 左寄せ（isProcessing時は非表示）
│（または [ カジュアル | 普通 | 丁寧 | ビジネス ]）
│         [ 変換をキャンセル ]      │  ← isProcessing時のみ表示
└─────────────────────────────────┘
│          AdBannerView            │  ← isAdRemoved=falseの場合のみ
└─────────────────────────────────┘
```

## デフォルト

モード：要約（summarize）

## モード切り替え

下部固定エリアの右寄せに `Picker` の `.segmented` スタイルで配置する。

```swift
Picker("モード", selection: $viewModel.mode) {
    Text("要約").tag(Mode.summarize)
    Text("リライト").tag(Mode.rewrite)
}
.pickerStyle(.segmented)
.fixedSize()
```

- **isProcessing == true の場合は非表示**
- モード変更時に `isProcessing == true` の場合は14章の仕様に従いキャンセル＆ダイアログ表示
- `lengthStep`・`toneStep` はモード変更時にリセットしない（選択値を保持する）

## 入力エリア

- 全削除ボタンあり（`xmark.circle.fill` アイコン、入力テキスト右上に配置）
  - タップ時：`inputText` を空にする
  - 同時に `outputText` もクリアする
  - `lastExecutedLengthStep` / `lastExecutedToneStep` を `nil` にリセットする
  - `inputText` が空の場合は非表示
- 最大1500文字（超過時は変換ボタン無効化・文字数カウントを赤字表示）
- クリップボード自動読み込み（設定ON/OFF）
- 既に文字がある場合は読み込まない

## 出力エリア

- ワンタップコピー
  - 出力エリア右上に `doc.on.doc` アイコンのコピーボタンを配置
  - タップで `UIPasteboard.general.string = outputText`
  - コピー成功時はアイコンを一時的に `checkmark` に変更（1秒後に元に戻す）
  - `outputText` が空の場合はコピーボタンを非表示
- 出力文字数カウントを表示する（例：`234 文字`）
- 文字数上限はAPIが `GenerationOptions(maximumResponseTokens: 800)` で制御する（UIでの切り捨てなし）

## 実行済み粒度の表示

- 入力エリアと出力エリアの間に `lastExecutedLengthStep`（summarize時）または `lastExecutedToneStep`（rewrite時）の表示ラベルを左寄せで表示する
- 出力テキストが空（未実行）の場合は非表示

## 変換ボタン（下部固定エリア）

| 状態 | 表示内容 |
|------|---------|
| 通常（summarize） | `[ 短く \| 簡潔 \| 標準 \| 詳しく ]`（左寄せ） + `[ 要約 \| リライト ]`（右寄せ） |
| 通常（rewrite） | `[ カジュアル \| 普通 \| 丁寧 \| ビジネス ]`（左寄せ） + `[ 要約 \| リライト ]`（右寄せ） |
| 処理中 | `[ 変換をキャンセル ]`（モード切り替え・変換ボタン非表示） |
| 入力空・文字超過・モデル未対応 | ボタンをdisabled表示 |

- 変換ボタンは `safeAreaInset(edge: .bottom)` でスクロール外に固定
- `lastExecutedLengthStep` / `lastExecutedToneStep` と一致するボタンに下線を表示

---

# 10. 履歴仕様

- 変換成功時のみ保存
- ViewModel内で保存呼び出し
- SwiftData使用
- 削除可能

保存項目：

- 入力テキスト
- 出力テキスト
- モード
- 長さ値（lengthStep）
- トーン値（toneStep）
- 日付

### 未使用パラメータの保存ルール

- **summarize 実行時**：`toneStep` は現在の `viewModel.toneStep` の値をそのまま保存する（プロンプトには使用しない）
- **rewrite 実行時**：`lengthStep` は現在の `viewModel.lengthStep` の値をそのまま保存する（プロンプトには使用しない）
- 履歴復元時に両方の値が復元されるため、モード切り替え後も前回の設定が維持される

---

# 11. モデル未対応端末対応

## 起動時チェック

LanguageModel生成を試行。

失敗時：

- ダイアログ表示
- 変換機能無効化

## ダイアログ内容

タイトル：この端末では利用できません

本文：本アプリはApple Intelligence対応端末でのみご利用いただけます。

---

# 12. ViewModel状態管理

```swift
@MainActor
final class MainViewModel: ObservableObject {

    @Published var inputText: String = ""
    @Published var outputText: String = ""

    @Published var mode: Mode = .summarize

    // UIから直接バインドしない。convert(lengthStep:) 経由で更新される。
    // @Published は履歴復元（21章）で外部から代入するために必要。
    @Published var lengthStep: Int = 0  // 0〜3、デフォルト：ultraShort（短く）
    @Published var toneStep: Int = 2    // 0〜3、デフォルト：formal（丁寧）、rewrite時のみ表示

    @Published var lastExecutedLengthStep: Int? = nil  // 最後に実行したLength（下線表示用）
    @Published var lastExecutedToneStep: Int? = nil    // 最後に実行したTone（下線表示用）

    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false  // 変換エラー時のAlert表示フラグ

    @Published var isModelAvailable: Bool = true
    @Published var showModelUnavailableAlert: Bool = false
    @Published var showModeChangedCancelAlert: Bool = false

    // isClipboardAutoLoadEnabled は SettingViewModel が保持。MainViewModel は持たない（28章参照）

    private let aiRepository: AIRepositoryProtocol
    private let historyRepository: HistoryRepositoryProtocol
    private var currentTask: Task<Void, Never>?
    private var hasShownModeChangeCancelAlert: Bool = false

    // MARK: - Init（23章 AppDependencies から呼ばれる）

    init(ai: AIRepositoryProtocol, history: HistoryRepositoryProtocol, isModelAvailable: Bool) {
        self.aiRepository = ai
        self.historyRepository = history
        self.isModelAvailable = isModelAvailable
        if !isModelAvailable {
            self.showModelUnavailableAlert = true
        }
    }

    // 変換ボタンの有効判定（計算プロパティ）
    // ※ isProcessing は含めない。処理中はボタン自体が非表示になるため、
    //   canConvert は「入力状態の有効性」のみを判定する。
    //   実行可否の最終判定は convert() 内で isProcessing も含めて行う（13章参照）。
    var canConvert: Bool { isModelAvailable && !inputText.isEmpty && inputText.count <= 1500 }
}
```

## エラー表示仕様

変換失敗時は Alert ダイアログで表示する（モデル未対応・モード変更キャンセルのダイアログと統一）。

| エラー | タイトル | 本文 |
|--------|---------|------|
| generationFailed | 変換に失敗しました | テキストの変換中にエラーが発生しました。もう一度お試しください。 |
| inputTooLong | 文字数が超過しています | 入力テキストを1500文字以内にしてください。 |
| unknown | エラーが発生しました | 予期しないエラーが発生しました。もう一度お試しください。 |

- `CancellationError` はダイアログを表示しない（13章参照）
- `modelUnavailable` は11章のダイアログで処理済みのため、ここでは対象外
- `errorMessage` に値をセットすると `showErrorAlert = true` になり Alert が表示される

```swift
@Published var showErrorAlert: Bool = false

// convert() 内のエラーハンドリング
catch let error as AIRepositoryError {
    switch error {
    case .generationFailed:
        errorMessage = "テキストの変換中にエラーが発生しました。もう一度お試しください。"
    case .inputTooLong:
        errorMessage = "入力テキストを1500文字以内にしてください。"
    case .unknown(_):
        errorMessage = "予期しないエラーが発生しました。もう一度お試しください。"
    case .modelUnavailable:
        break // 11章で処理済み
    }
    showErrorAlert = (errorMessage != nil)
}
```

---

# 13. 実行制御

## 実行条件

`convert()` メソッド内で以下をすべて満たすことを確認する（`canConvert` + `isProcessing` のガード）。

- canConvert == true（isModelAvailable == true、inputTextが空でない、1500文字以内）
- isProcessing == false

## convert メソッドのシグネチャ

```swift
// summarize モードで呼ばれる
func convert(lengthStep: Int)

// rewrite モードで呼ばれる
func convert(toneStep: Int)
```

- 呼び出し時に `self.lengthStep` / `self.toneStep` を引数値で更新してから実行する
- 変換成功後に `lastExecutedLengthStep` / `lastExecutedToneStep` を更新する
- 変換失敗・キャンセル時は `lastExecuted` を更新しない

## キャンセル仕様

```swift
func cancel()
```

- `currentTask?.cancel()` を呼び出す
- 実行時に既存Taskをcancel（最新のみ有効）
- CancellationErrorは表示しない

---

# 14. モード変更時仕様

## 条件

- isProcessing == true
- mode変更

## 検知方法

View 層で `onChange(of: viewModel.mode)` を使用して検知し、ViewModel のハンドラを呼び出す。

```swift
// MainView 内
.onChange(of: deps.mainViewModel.mode) { _, _ in
    deps.mainViewModel.handleModeChange()
}
```

```swift
// MainViewModel
func handleModeChange() {
    guard isProcessing else { return }
    currentTask?.cancel()
    isProcessing = false
    if !hasShownModeChangeCancelAlert {
        showModeChangedCancelAlert = true
        hasShownModeChangeCancelAlert = true
    }
}
```

## 挙動

- currentTask?.cancel()
- isProcessing = false
- 再実行しない
- ダイアログ表示（1セッション1回のみ）

## フラグの役割分担

| 変数 | 役割 |
|------|------|
| `showModeChangedCancelAlert` | `@Published`。`true` にするとViewがアラートを表示する |
| `hasShownModeChangeCancelAlert` | `private`。セッション中に1回だけ表示する制御フラグ。表示済みなら `showModeChangedCancelAlert` を `true` にしない |

## ダイアログ内容

タイトル：処理を停止しました

本文：モード変更のため、現在の処理を停止しました。

ボタン：OK

---

# 15. エラー型

```swift
enum AIRepositoryError: Error {
    case modelUnavailable
    case inputTooLong
    case generationFailed
    case unknown(Error)
}
```

---

# 16. Model 型定義
<!-- ※ 旧16章（広告仕様）は24章に統合済み。 -->

## Mode

```swift
enum Mode: String, CaseIterable {
    case summarize = "summarize"
    case rewrite   = "rewrite"

    /// HistoryRowView 等で表示するラベル
    var displayLabel: String {
        switch self {
        case .summarize: return "要約"
        case .rewrite:   return "リライト"
        }
    }
}
```

## LengthInstruction

```swift
enum LengthInstruction {
    case ultraShort
    case concise
    case balanced
    case detailed

    var instruction: String {
        switch self {
        case .ultraShort: return "できるだけ短く、1〜2文で答えてください。"
        case .concise:    return "要点のみを簡潔にまとめてください。"
        case .balanced:   return "重要な情報を残しながら適切な長さにまとめてください。"
        case .detailed:   return "情報をできるだけ保持しながら、読みやすくまとめてください。"
        }
    }

    static func from(_ step: Int) -> LengthInstruction {
        switch step {
        case 0:  return .ultraShort
        case 1:  return .concise
        case 2:  return .balanced
        case 3:  return .detailed
        default: return .ultraShort
        }
    }

    static func label(for step: Int) -> String {
        switch step {
        case 0:  return "短く"
        case 1:  return "簡潔"
        case 2:  return "標準"
        case 3:  return "詳しく"
        default: return "短く"
        }
    }
}
```

## ToneInstruction

```swift
enum ToneInstruction {
    case casual
    case polite
    case formal
    case business

    var instruction: String {
        switch self {
        case .casual:   return "フレンドリーでカジュアルな口調で書いてください。"
        case .polite:   return "やや丁寧で読みやすい口調で書いてください。"  // 表示ラベル：普通
        case .formal:   return "丁寧で誠実な口調で書いてください。"
        case .business: return "ビジネス文書として適切なフォーマルな口調で書いてください。"
        }
    }

    static func from(_ step: Int) -> ToneInstruction {
        switch step {
        case 0:  return .casual
        case 1:  return .polite
        case 2:  return .formal
        case 3:  return .business
        default: return .casual
        }
    }

    static func label(for step: Int) -> String {
        switch step {
        case 0:  return "カジュアル"
        case 1:  return "普通"
        case 2:  return "丁寧"
        case 3:  return "ビジネス"
        default: return "カジュアル"
        }
    }
}
```

## LanguageInstruction

```swift
enum LanguageInstruction {
    case japanese
    case english

    var instruction: String {
        switch self {
        case .japanese: return "必ず日本語で出力してください。"
        case .english:  return "Output in English only."
        }
    }
}
```

---

# 17. SwiftData HistoryItem スキーマ

```swift
import SwiftData
import Foundation

@Model
final class HistoryItem: Identifiable {
    var id: UUID
    var inputText: String
    var outputText: String
    var mode: String    // Mode.rawValue を保存
    var lengthStep: Int // 0〜3
    var toneStep: Int   // 0〜3
    var createdAt: Date

    init(
        inputText: String,
        outputText: String,
        mode: Mode,
        lengthStep: Int,
        toneStep: Int
    ) {
        self.id         = UUID()
        self.inputText  = inputText
        self.outputText = outputText
        self.mode       = mode.rawValue
        self.lengthStep = lengthStep
        self.toneStep   = toneStep
        self.createdAt  = Date()
    }
}
```

### 備考

- `mode` は `String` で保存し、復元時に `Mode(rawValue:)` で変換する
- 並び順は `createdAt` の降順（新しい順）
- 削除は `modelContext.delete(item)` で行う

---

# 18. UserDefaults キー一覧

| キー | 型 | デフォルト値 | 用途 |
|------|----|-------------|------|
| `isClipboardAutoLoadEnabled` | Bool | true | クリップボード自動読み込みON/OFF |

```swift
extension UserDefaults {
    var isClipboardAutoLoadEnabled: Bool {
        get { object(forKey: "isClipboardAutoLoadEnabled") as? Bool ?? true }
        set { set(newValue, forKey: "isClipboardAutoLoadEnabled") }
    }
}
```

---

# 19. 入力文字数制限の扱い

## 文字数制限（UI・AI共通：1500文字）

- UI・AI ともに **1500文字** で統一する
- `TextEditor` の `onChange` で文字数を監視し、1500文字を超えたら変換ボタンを無効化する
- 切り捨ては行わない（ユーザーの文章を破壊するため）
- Repository には必ず1500文字以内のテキストが渡される

## 入力エリアのUI表示

- 現在の文字数を表示する（例：`1234 / 1500`）
- 1500文字超過時は文字数カウントを赤字にする
- 変換ボタンを無効化（グレーアウト）する

## 出力エリアのUI表示

- 出力後に文字数カウントを表示する（例：`234 文字`）
- 上限はAPIが `GenerationOptions(maximumResponseTokens: 800)` で制御し、UIでの切り捨ては行わない

---

# 20. ナビゲーション構造

## 構成

`NavigationStack` を使い、MainView を起点とした単方向ナビゲーション。TabView は使用しない。

```
MainView（ルート）
├── HistoryView（NavigationLinkで遷移）
└── SettingView（NavigationLinkで遷移）
```

## ナビゲーションボタン配置

- MainView のナビゲーションバーに配置
- 右：履歴ボタン（clock.fill アイコン）
- 左：設定ボタン（gearshape.fill アイコン）

```swift
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        NavigationLink(destination: SettingView()) {
            Image(systemName: "gearshape.fill")
        }
    }
    ToolbarItem(placement: .navigationBarTrailing) {
        NavigationLink(destination: HistoryView()) {
            Image(systemName: "clock.fill")
        }
    }
}
```

---

# 20-1. HistoryViewModel 状態管理

```swift
@MainActor
final class HistoryViewModel: ObservableObject {

    @Published var items: [HistoryItem] = []

    private let historyRepository: HistoryRepositoryProtocol

    init(history: HistoryRepositoryProtocol) {
        self.historyRepository = history
    }

    /// 履歴一覧を取得して items を更新する
    func loadItems() {
        do {
            items = try historyRepository.fetchAll()
        } catch {
            items = []
        }
    }

    /// 履歴を MainViewModel に復元する（21章参照）
    func restore(_ item: HistoryItem, to viewModel: MainViewModel) {
        viewModel.inputText  = item.inputText
        viewModel.outputText = ""
        viewModel.mode       = Mode(rawValue: item.mode) ?? .summarize
        viewModel.lengthStep = item.lengthStep
        viewModel.toneStep   = item.toneStep
        viewModel.lastExecutedLengthStep = nil
        viewModel.lastExecutedToneStep   = nil
    }

    /// スワイプ削除（onDelete の indexSet を受け取る）
    func delete(at indexSet: IndexSet) {
        for index in indexSet {
            let item = items[index]
            do {
                try historyRepository.delete(item)
            } catch {
                // 削除失敗時は無視（リロードで整合性を回復）
            }
        }
        loadItems()  // 削除後にリストを再取得
    }
}
```

### 備考

- `loadItems()` は HistoryView の `onAppear` で呼び出す
- `items` は `@Published` のため、変更時にViewが自動更新される

---

# 21. HistoryView 仕様

## HistoryRowView 表示内容

| 項目 | 内容 |
|------|------|
| モード | 「要約」または「リライト」ラベル |
| 入力テキスト冒頭 | 先頭50文字程度を1行で表示（truncated） |
| 日時 | `yyyy/MM/dd HH:mm` 形式 |

## タップ時の挙動

- HistoryItem の `inputText` / `mode` / `lengthStep` / `toneStep` を MainViewModel に復元する
- NavigationStack を pop して MainView に戻る
- MainView の出力エリアはクリアする（再実行はしない）

## 復元処理

`HistoryViewModel.restore()` を呼び出す（詳細は20-1章参照）。

## View層での呼び出し

`AppDependencies` 経由で `mainViewModel` を取得し、`HistoryViewModel.restore` に渡す。
復元後は `@Environment(\.dismiss)` で pop する。

```swift
// HistoryView 内
struct HistoryView: View {
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            ForEach(deps.historyViewModel.items) { item in
                HistoryRowView(item: item)
                    .onTapGesture {
                        deps.historyViewModel.restore(item, to: deps.mainViewModel)
                        dismiss()
                    }
            }
            .onDelete { indexSet in
                deps.historyViewModel.delete(at: indexSet)
            }
        }
        .onAppear {
            deps.historyViewModel.loadItems()
        }
    }
}
```

## 削除

- スワイプで削除（`onDelete`）

---

# 22. AIRepositoryProtocol シグネチャ

```swift
protocol AIRepositoryProtocol {
    func summarize(
        input: String,
        length: LengthInstruction,
        language: LanguageInstruction
    ) async throws -> String

    func rewrite(
        input: String,
        tone: ToneInstruction,
        language: LanguageInstruction
    ) async throws -> String
}
```

- 戻り値は変換後テキスト（`String`）
- エラーは `AIRepositoryError` を throw する

## AIRepositoryUnavailable（stub）

AI モデルが利用不可の端末でもアプリを起動できるようにするための stub。
実際の変換処理は `MainViewModel` が `isModelAvailable == false` で弾くため、このメソッドが呼ばれることはない。

```swift
final class AIRepositoryUnavailable: AIRepositoryProtocol {
    func summarize(input: String, length: LengthInstruction, language: LanguageInstruction) async throws -> String {
        throw AIRepositoryError.modelUnavailable
    }
    func rewrite(input: String, tone: ToneInstruction, language: LanguageInstruction) async throws -> String {
        throw AIRepositoryError.modelUnavailable
    }
}
```

---

# 23. DI（依存性注入）仕様

## 方針

`AppDependencies` を `@StateObject` で生成し、`@EnvironmentObject` で View 階層に流す。

## AppDependencies

```swift
@MainActor
final class AppDependencies: ObservableObject {
    let aiRepository: AIRepositoryProtocol
    let historyRepository: HistoryRepositoryProtocol
    let mainViewModel: MainViewModel
    let historyViewModel: HistoryViewModel
    let settingViewModel: SettingViewModel

    init() {
        // AIRepository 生成失敗時は AppDependencies 初期化を成功させ、
        // MainViewModel 側で isModelAvailable = false にしてダイアログ表示する
        let aiResult = Result { try AIRepository() }
        let ai: AIRepositoryProtocol
        let modelAvailable: Bool
        switch aiResult {
        case .success(let repo):
            ai = repo
            modelAvailable = true
        case .failure:
            ai = AIRepositoryUnavailable()  // throw のみする stub
            modelAvailable = false
        }

        let container = try! ModelContainer(for: HistoryItem.self)
        let history   = HistoryRepository(container: container)

        aiRepository      = ai
        historyRepository = history
        mainViewModel     = MainViewModel(ai: ai, history: history, isModelAvailable: modelAvailable)
        historyViewModel  = HistoryViewModel(history: history)
        settingViewModel  = SettingViewModel()
    }
}
```

## エントリーポイント

`scenePhase` 監視を含む完全版は28章を参照。以下は DI の流れのみ示す簡易版。

```swift
@main
struct QuickRetextApp: App {
    @StateObject var deps = AppDependencies()
    // ... scenePhase 監視等は 28章参照
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(deps)
        }
    }
}
```

## View での受け取り

```swift
struct MainView: View {
    @EnvironmentObject var deps: AppDependencies
    // deps.mainViewModel を使う
}
```

---

# 24. 広告バナー仕様

## AdMob 設定

- SDK初期化：`AppDelegate` または `QuickRetextApp.init()` で `GADMobileAds.sharedInstance().start(completionHandler: nil)` を呼ぶ
- 広告ユニットID：本番IDは別途管理（ソースコードにハードコードしない。`Info.plist` または環境変数で管理）
- テスト時は Google AdMob のテスト用バナーID `ca-app-pub-3940256099942544/2934735716` を使用する
- `Info.plist` に `GADApplicationIdentifier` キーでAdMobアプリIDを設定すること

## 表示位置

- **全画面共通**：MainView / HistoryView / SettingView の各画面下部に表示
- SafeArea の上、画面最下部に固定
- **MainView のみ**：`safeAreaInset(edge: .bottom)` の下部固定エリア（ControlPanelView）の下に配置する

## 非表示制御

- `AdBannerView` が `isVisible: Bool` プロパティを持つ
- `isVisible = false` のとき `frame(height: 0)` で非表示（スペースも消える）
- 購入済み判定は `SettingViewModel` が保持し、`AppDependencies` 経由で各 View に渡す

```swift
struct AdBannerView: UIViewRepresentable {
    var isVisible: Bool
    // isVisible == false のとき height 0 で非表示
}
```

```swift
// 各Viewの下部
AdBannerView(isVisible: !deps.settingViewModel.isAdRemoved)
```

---

# 25. 下部固定エリア UI仕様

## 配置

`safeAreaInset(edge: .bottom)` でスクロール外に固定する。AdBannerView の上に配置。

## 状態別表示

### 通常時（isProcessing == false）

```
[ 短く | 簡潔 | 標準 | 詳しく ]（左寄せ）  [ 要約 | リライト ]（右寄せ）
```

- 変換ボタン群（summarize: Length 4ボタン / rewrite: Tone 4ボタン）を左寄せで配置
- モード切り替え Picker を右寄せで配置
- `canConvert == false`（入力空・文字超過・モデル未対応）の場合は変換ボタンを `.disabled(true)` で表示

### 処理中（isProcessing == true）

```
         [ 変換をキャンセル ]
```

- 変換ボタン群・モード切り替えを非表示
- 「変換をキャンセル」ボタンのみ表示（`.bordered` スタイル）

## 実装イメージ

変換ボタン群は別コンポーネントにせず `ControlPanelView` 内に直接実装する（ディレクトリ構成の `Components/ControlPanelView.swift` に含まれる）。

```swift
// ControlPanelView.swift（下部固定エリア）
struct ControlPanelView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack {
            if viewModel.isProcessing {
                Button("変換をキャンセル") { viewModel.cancel() }
                    .buttonStyle(.bordered)
            } else {
                HStack {
                    // 変換ボタン群（モードに応じて切り替え）
                    if viewModel.mode == .summarize {
                        ForEach(0..<4, id: \.self) { step in
                            Button(LengthInstruction.label(for: step)) {
                                viewModel.convert(lengthStep: step)
                            }
                            .underline(viewModel.lastExecutedLengthStep == step)
                            .disabled(!viewModel.canConvert)
                        }
                    } else {
                        ForEach(0..<4, id: \.self) { step in
                            Button(ToneInstruction.label(for: step)) {
                                viewModel.convert(toneStep: step)
                            }
                            .underline(viewModel.lastExecutedToneStep == step)
                            .disabled(!viewModel.canConvert)
                        }
                    }
                    Spacer()
                    // モード切り替え
                    Picker("モード", selection: $viewModel.mode) {
                        Text("要約").tag(Mode.summarize)
                        Text("リライト").tag(Mode.rewrite)
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
            }
        }
    }
}
```

`canConvert` は `isModelAvailable && !inputText.isEmpty && inputText.count <= 1500` の計算プロパティ。

---

# 26. HistoryRepositoryProtocol シグネチャ

```swift
@MainActor
protocol HistoryRepositoryProtocol {
    func save(_ item: HistoryItem) throws
    func fetchAll() throws -> [HistoryItem]
    func delete(_ item: HistoryItem) throws
}
```

## 実装（HistoryRepository）

```swift
@MainActor
final class HistoryRepository: HistoryRepositoryProtocol {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func save(_ item: HistoryItem) throws {
        container.mainContext.insert(item)
        try container.mainContext.save()
    }

    func fetchAll() throws -> [HistoryItem] {
        let descriptor = FetchDescriptor<HistoryItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try container.mainContext.fetch(descriptor)
    }

    func delete(_ item: HistoryItem) throws {
        container.mainContext.delete(item)
        try container.mainContext.save()
    }
}
```

---

# 27. SwiftData ModelContainer 設定

## 生成場所

`AppDependencies.init()` で生成し、`HistoryRepository` に注入する。

詳細なコードは23章参照。

- `ModelContainer(for: HistoryItem.self)` の生成失敗は致命的エラーのため `try!` を使用する
- AI モデルが利用不可の場合は `AIRepositoryUnavailable`（stub）を注入し、`MainViewModel` に `isModelAvailable: false` を渡す
- `ModelContainer` を生成して `HistoryRepository(container:)` に注入する

---

# 28. SettingViewModel 状態変数

```swift
@MainActor
final class SettingViewModel: ObservableObject {

    // 広告削除購入済みフラグ（StoreKit entitlements で管理）
    @Published var isAdRemoved: Bool = false

    // クリップボード自動読み込み（UserDefaults で永続化）
    @Published var isClipboardAutoLoadEnabled: Bool = UserDefaults.standard.isClipboardAutoLoadEnabled {
        didSet {
            UserDefaults.standard.isClipboardAutoLoadEnabled = isClipboardAutoLoadEnabled
        }
    }

    @Published var isPurchasing: Bool = false  // 購入処理中フラグ

    private static let productID = "com.xxx.QuickRetext.removeAds"

    // アプリ起動・フォアグラウンド復帰時に購入状態を確認
    func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID {
                await MainActor.run { isAdRemoved = true }
                return
            }
        }
        await MainActor.run { isAdRemoved = false }
    }

    // MARK: - 購入処理

    /// 「広告を非表示にする」ボタンから呼ばれる
    func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let products = try await Product.products(for: [Self.productID])
            guard let product = products.first else { return }

            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(_) = verification {
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
            // 購入エラー時は何もしない（isAdRemoved は変更しない）
        }
    }

    /// 「購入を復元する」ボタンから呼ばれる
    func restore() async {
        do {
            try await AppStore.sync()
            await checkPurchaseStatus()
        } catch {
            // 復元エラー時は何もしない
        }
    }
}
```

## 購入状態確認タイミング

- アプリ初回起動時：`onChange(of: scenePhase)` の初回 `.active` 遷移で自動的にカバーされる
- フォアグラウンド復帰時：同じ `onChange(of: scenePhase)` で処理

> **補足**: `scenePhase` はアプリ起動直後に `.active` へ遷移するため、`onAppear` を別途追加する必要はない。`onChange` の1箇所で初回起動・復帰の両方を処理する。

```swift
@main
struct QuickRetextApp: App {
    @StateObject var deps = AppDependencies()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(deps)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await deps.settingViewModel.checkPurchaseStatus() }
                deps.mainViewModel.loadClipboardIfNeeded(
                    isEnabled: deps.settingViewModel.isClipboardAutoLoadEnabled
                )
            }
        }
    }
}
```

---

# 29. クリップボード自動読み込み仕様

## 挙動

- フォアグラウンド復帰時（`scenePhase == .active`）にチェック
- `isClipboardAutoLoadEnabled == true` かつ `inputText.isEmpty` のときのみ読み込む
- `UIPasteboard.general.string` を `inputText` にセット

## プライバシー対応

iOS 16以降、`UIPasteboard.general.string` にアクセスするとシステムがペースト許可バナー（「○○が△△からペーストしました」）を表示する。
これはOS標準の挙動であり、アプリ側で抑制できないため、以下の方針とする。

- `UIPasteboard.general.hasStrings` で事前にクリップボードにテキストがあるか確認し、空の場合はアクセスしない（不要なバナー表示を回避）
- バナー表示はOS標準動作のため、アプリ側で追加のダイアログは表示しない

## 実装場所

`MainViewModel` に実装する。`isClipboardAutoLoadEnabled` は `SettingViewModel` が保持するため引数で受け取る。

```swift
func loadClipboardIfNeeded(isEnabled: Bool) {
    guard isEnabled,
          inputText.isEmpty,
          UIPasteboard.general.hasStrings,  // 事前チェック（不要なバナー回避）
          let text = UIPasteboard.general.string,
          !text.isEmpty else { return }
    inputText = text
}
```

`QuickRetextApp` の `scenePhase == .active` で購入確認と同時に呼ぶ。

```swift
.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .active {
        Task { await deps.settingViewModel.checkPurchaseStatus() }
        deps.mainViewModel.loadClipboardIfNeeded(
            isEnabled: deps.settingViewModel.isClipboardAutoLoadEnabled
        )
    }
}
```
