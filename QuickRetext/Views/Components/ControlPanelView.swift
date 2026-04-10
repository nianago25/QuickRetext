import SwiftUI
import QuickRetext_Models
import QuickRetext_ViewModels

struct ControlPanelView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack(spacing: 8) {
            if viewModel.isProcessing {
                Button("変換をキャンセル") {
                    viewModel.cancel()
                }
                .buttonStyle(.bordered)
            } else {
                // 上段: モード切替（フル幅セグメント）
                Picker("モード", selection: $viewModel.mode) {
                    Text("要約").tag(Mode.summarize)
                    Text("リライト").tag(Mode.rewrite)
                }
                .pickerStyle(.segmented)

                // 下段: オプションボタン（ピル型）
                HStack(spacing: 8) {
                    if viewModel.mode == .summarize {
                        ForEach(0..<4, id: \.self) { step in
                            PillButton(
                                label: LengthInstruction.label(for: step),
                                isSelected: viewModel.lastExecutedLengthStep == step,
                                isDisabled: !viewModel.canConvert
                            ) {
                                viewModel.convert(lengthStep: step)
                            }
                        }
                    } else {
                        ForEach(0..<4, id: \.self) { step in
                            PillButton(
                                label: ToneInstruction.label(for: step),
                                isSelected: viewModel.lastExecutedToneStep == step,
                                isDisabled: !viewModel.canConvert
                            ) {
                                viewModel.convert(toneStep: step)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

// MARK: - PillButton

private struct PillButton: View {
    let label: String
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1.0)
        .foregroundStyle(isSelected ? Color.accentColor : .primary)
    }
}
