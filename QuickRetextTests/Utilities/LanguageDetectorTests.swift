import Testing
@testable import QuickRetext_Models
@testable import QuickRetext_Utilities

@Suite("LanguageDetector Tests")
struct LanguageDetectorTests {

    // MARK: - 日本語判定

    @Test("ひらがな主体のテキストは japanese を返す")
    func hiraganaTextIsJapanese() {
        let text = "これはてすとのてきすとです。にほんごのぶんしょうをにゅうりょくします。"
        #expect(LanguageDetector.detect(text) == .japanese)
    }

    @Test("カタカナ主体のテキストは japanese を返す")
    func katakanaTextIsJapanese() {
        let text = "コレハテストノテキストデス。ニホンゴノブンショウヲニュウリョクシマス。"
        #expect(LanguageDetector.detect(text) == .japanese)
    }

    @Test("漢字主体のテキストは japanese を返す")
    func kanjiTextIsJapanese() {
        let text = "日本語のテキスト変換アプリです。要約とリライトをサポートしています。"
        #expect(LanguageDetector.detect(text) == .japanese)
    }

    // MARK: - 英語判定

    @Test("英語テキストは english を返す")
    func englishTextIsEnglish() {
        let text = "This is a test text. The application supports summarization and rewriting."
        #expect(LanguageDetector.detect(text) == .english)
    }

    @Test("数字・記号のみのテキストは english を返す")
    func symbolOnlyTextIsEnglish() {
        let text = "1234567890 !@#$%^&*()"
        #expect(LanguageDetector.detect(text) == .english)
    }

    @Test("空文字列は english を返す")
    func emptyTextIsEnglish() {
        #expect(LanguageDetector.detect("") == .english)
    }

    // MARK: - 境界値

    @Test("日本語が正確に50%の場合は japanese を返す")
    func exactlyFiftyPercentJapaneseIsJapanese() {
        // 2文字中1文字（50%）が日本語
        let text = "あa"
        #expect(LanguageDetector.detect(text) == .japanese)
    }

    @Test("日本語が50%未満の場合は english を返す")
    func lessThanFiftyPercentJapaneseIsEnglish() {
        // 3文字中1文字（33%）が日本語
        let text = "あab"
        #expect(LanguageDetector.detect(text) == .english)
    }

    @Test("100文字を超えるテキストは先頭100文字のみで判定する")
    func longTextUsesFirst100Characters() {
        // 先頭100文字は英語、それ以降は日本語
        let englishPart = String(repeating: "a", count: 100)
        let japanesePart = String(repeating: "あ", count: 100)
        let text = englishPart + japanesePart
        #expect(LanguageDetector.detect(text) == .english)
    }
}
