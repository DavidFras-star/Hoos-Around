import SwiftUI

/// Presents 1–2 micro tie-breaker cards in sequence (only EI and/or TF).
/// After resolving all pending ties, returns to PersonalityReviewView.
struct TieBreakerQuestionView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @State private var idx: Int = 0
    @State private var pickedRight: Bool? = nil
    @State private var goNext = false

    private var axes: [Axis] { onboardingVM.pendingTieAxes }
    private var isLast: Bool { idx == max(axes.count - 1, 0) }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 8)

            if let axis = currentAxis {
                Text(title(for: axis))
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text(subtitle(for: axis))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 14) {
                    card(text: leftText(for: axis), pickRight: false)
                    card(text: rightText(for: axis), pickRight: true)
                }
                .padding(.horizontal)
            }

            Spacer()

            Button {
                commit()
            } label: {
                Text(isLast ? "Done" : "Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(pickedRight == nil ? Color.white.opacity(0.35) : Color.white)
                    .foregroundColor(pickedRight == nil ? .white.opacity(0.7) : .purple)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(pickedRight == nil)
            .padding(.horizontal)
            .padding(.bottom, 20)

            NavigationLink("", isActive: $goNext) {
                PersonalityReviewView().environmentObject(onboardingVM)
            }
            .hidden()
        }
        .background(
            LinearGradient(colors: [Color.purple, Color.black],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        )
        .onChange(of: idx) { _ in pickedRight = nil }
    }

    // MARK: - Derivations

    private var currentAxis: Axis? {
        guard axes.indices.contains(idx) else { return nil }
        return axes[idx]
    }

    private func title(for axis: Axis) -> String {
        switch axis {
        case .EI: return "Quick Tie-Breaker: Energy"
        case .TF: return "Quick Tie-Breaker: Decision Style"
        case .JP: return "Lifestyle"
        case .NS: return "Perspective"
        }
    }

    private func subtitle(for axis: Axis) -> String {
        switch axis {
        case .EI:
            return "When I have unexpected free time, I usually…"
        case .TF:
            return "When I need to make a quick decision, I usually trust…"
        case .JP, .NS:
            return ""
        }
    }

    private func leftText(for axis: Axis) -> String {
        switch axis {
        case .EI:
            return "Recharge solo or do something low-key"      // INTROVERT
        case .TF:
            return "What makes the most sense logically"        // LOGIC
        case .JP, .NS:
            return ""
        }
    }

    private func rightText(for axis: Axis) -> String {
        switch axis {
        case .EI:
            return "Reach out to people or find something social" // EXTROVERT
        case .TF:
            return "What feels right in the moment"               // VALUES
        case .JP, .NS:
            return ""
        }
    }

    // MARK: - UI

    private func card(text: String, pickRight: Bool) -> some View {
        let selected = (pickedRight == pickRight)
        return Button {
            pickedRight = pickRight
        } label: {
            HStack {
                Text(text)
                    .font(.headline)
                    .foregroundColor(.purple)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(Color.white.opacity(selected ? 0.95 : 0.85))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(radius: selected ? 6 : 2)
        }
        .buttonStyle(.plain)
    }

    private func commit() {
        guard let axis = currentAxis, let pickedRight else { return }
        onboardingVM.applyTieBreaker(axis: axis, pickedRight: pickedRight)

        // advance or finish
        if idx < axes.count - 1 {
            idx += 1
        } else {
            goNext = true
        }
    }
}
