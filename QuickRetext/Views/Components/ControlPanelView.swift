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
                HStack {
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

                    Picker("モード", selection: $viewModel.mode) {
                        Text("要約").tag(Mode.summarize)
                        Text("リライト").tag(Mode.rewrite)
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
