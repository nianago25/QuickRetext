import Testing
@testable import QuickRetext

@Suite("LengthInstruction Tests")
struct LengthInstructionTests {

    // MARK: - from(step:)

    @Test("step 0 は ultraShort を返す")
    func step0IsUltraShort() {
        #expect(LengthInstruction.from(0) == .ultraShort)
    }

    @Test("step 1 は concise を返す")
    func step1IsConcise() {
        #expect(LengthInstruction.from(1) == .concise)
    }

    @Test("step 2 は balanced を返す")
    func step2IsBalanced() {
        #expect(LengthInstruction.from(2) == .balanced)
    }

    @Test("step 3 は detailed を返す")
    func step3IsDetailed() {
        #expect(LengthInstruction.from(3) == .detailed)
    }

    @Test("範囲外の step は ultraShort にフォールバックする", arguments: [-1, 4, 99])
    func outOfRangeStepFallsBackToUltraShort(step: Int) {
        #expect(LengthInstruction.from(step) == .ultraShort)
    }

    // MARK: - label(for:)

    @Test("step 0 のラベルは '短く'")
    func step0Label() {
        #expect(LengthInstruction.label(for: 0) == "短く")
    }

    @Test("step 1 のラベルは '簡潔'")
    func step1Label() {
        #expect(LengthInstruction.label(for: 1) == "簡潔")
    }

    @Test("step 2 のラベルは '標準'")
    func step2Label() {
        #expect(LengthInstruction.label(for: 2) == "標準")
    }

    @Test("step 3 のラベルは '詳しく'")
    func step3Label() {
        #expect(LengthInstruction.label(for: 3) == "詳しく")
    }

    @Test("範囲外の step のラベルは '短く' にフォールバックする", arguments: [-1, 4])
    func outOfRangeLabelFallsBack(step: Int) {
        #expect(LengthInstruction.label(for: step) == "短く")
    }

    // MARK: - instruction

    @Test("ultraShort の instruction は空でない")
    func ultraShortInstructionIsNotEmpty() {
        #expect(!LengthInstruction.ultraShort.instruction.isEmpty)
    }

    @Test("全ケースの instruction が異なる")
    func allInstructionsAreUnique() {
        let instructions = [
            LengthInstruction.ultraShort.instruction,
            LengthInstruction.concise.instruction,
            LengthInstruction.balanced.instruction,
            LengthInstruction.detailed.instruction
        ]
        #expect(Set(instructions).count == 4)
    }
}
