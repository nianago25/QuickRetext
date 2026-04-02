import Testing
@testable import QuickRetext

@Suite("ToneInstruction Tests")
struct ToneInstructionTests {

    // MARK: - from(step:)

    @Test("step 0 は casual を返す")
    func step0IsCasual() {
        #expect(ToneInstruction.from(0) == .casual)
    }

    @Test("step 1 は polite を返す")
    func step1IsPolite() {
        #expect(ToneInstruction.from(1) == .polite)
    }

    @Test("step 2 は formal を返す")
    func step2IsFormal() {
        #expect(ToneInstruction.from(2) == .formal)
    }

    @Test("step 3 は business を返す")
    func step3IsBusiness() {
        #expect(ToneInstruction.from(3) == .business)
    }

    @Test("範囲外の step は casual にフォールバックする", arguments: [-1, 4, 99])
    func outOfRangeStepFallsBackToCasual(step: Int) {
        #expect(ToneInstruction.from(step) == .casual)
    }

    // MARK: - label(for:)

    @Test("step 0 のラベルは 'カジュアル'")
    func step0Label() {
        #expect(ToneInstruction.label(for: 0) == "カジュアル")
    }

    @Test("step 1 のラベルは '普通'")
    func step1Label() {
        #expect(ToneInstruction.label(for: 1) == "普通")
    }

    @Test("step 2 のラベルは '丁寧'")
    func step2Label() {
        #expect(ToneInstruction.label(for: 2) == "丁寧")
    }

    @Test("step 3 のラベルは 'ビジネス'")
    func step3Label() {
        #expect(ToneInstruction.label(for: 3) == "ビジネス")
    }

    @Test("範囲外の step のラベルは 'カジュアル' にフォールバックする", arguments: [-1, 4])
    func outOfRangeLabelFallsBack(step: Int) {
        #expect(ToneInstruction.label(for: step) == "カジュアル")
    }

    // MARK: - instruction

    @Test("全ケースの instruction が異なる")
    func allInstructionsAreUnique() {
        let instructions = [
            ToneInstruction.casual.instruction,
            ToneInstruction.polite.instruction,
            ToneInstruction.formal.instruction,
            ToneInstruction.business.instruction
        ]
        #expect(Set(instructions).count == 4)
    }
}
