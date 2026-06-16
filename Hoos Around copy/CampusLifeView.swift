import SwiftUI

struct CampusLifeView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    
    @State private var input: String = ""
    @State private var goNext: Bool = false
    

    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("Campus Life & Involvement")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Add clubs, activities, or teams you’re part of.")
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Input row
            HStack(spacing: 10) {
                TextField("e.g., Health Science Club", text: $input)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding(12)
                    .background(Color.white.opacity(0.15))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    if !onboardingVM.involvement.contains(trimmed) {
                        onboardingVM.involvement.append(trimmed)
                    }
                    input = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .accessibilityLabel("Add involvement")
                }
            }

            // Pills
            WrapPills(items: onboardingVM.involvement) { item in
                // Remove on tap (simple, fast)
                if let idx = onboardingVM.involvement.firstIndex(of: item) {
                    onboardingVM.involvement.remove(at: idx)
                }
            }
            .padding(.top, 4)

            Spacer(minLength: 8)

            // Next → PhotoPickerView
            Button {
                goNext = true
            } label: {
                Text("Next")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .foregroundColor(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            .padding(.top, 4)
        }
        .padding(20)
        .background(
            LinearGradient(colors: [Color.purple, Color.black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .background(
            // Hidden navigation link → your existing photo picker step
            NavigationLink("", isActive: $goNext) {
                PhotoPickerView()
                    .environmentObject(onboardingVM)  // SAME VM
            }
            .hidden()

        )
    }
}

// MARK: - Local pill wrap helper (self-contained)
private struct WrapPills: View {
    let items: [String]
    var onTap: ((String) -> Void)? = nil

    var body: some View {
        let cols = [GridItem(.adaptive(minimum: 120), spacing: 8)]
        LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button {
                    onTap?(item)
                } label: {
                    Text(item)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.purple)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.92))
                        .clipShape(Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(item)")
            }
        }
    }
}

