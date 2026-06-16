import SwiftUI

struct InterestsPickerView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    
    @State private var goNext = false
    @State private var selection = Set<String>()
    

    private let allInterests = [
        "Music","Fitness","Art","Movies","Cooking","Travel","Gaming",
        "Outdoors","Reading","Tech","Photography","Sports","Coffee","Deep Talks"
    ]
    private let limit = 8

    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("What are you into right now?")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Pick a few things that describe your interests.")
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Chips grid
            let cols = [GridItem(.adaptive(minimum: 110), spacing: 10)]
            ScrollView {
                LazyVGrid(columns: cols, spacing: 10) {
                    ForEach(allInterests, id: \.self) { tag in
                        let isOn = selection.contains(tag)
                        Button {
                            if isOn {
                                selection.remove(tag)
                            } else if selection.count < limit {
                                selection.insert(tag)
                            }
                        } label: {
                            Text(tag)
                                .font(.subheadline.weight(.semibold))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .frame(maxWidth: .infinity)
                                .background(isOn ? Color.white : Color.white.opacity(0.18))
                                .foregroundColor(isOn ? .purple : .white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 6)

                // Selection helper text
                Text("\(selection.count)/\(limit) selected")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 6)
            }

            // Next button → CampusLifeView
            Button {
                onboardingVM.interests = Array(selection)  // save into VM
                goNext = true                              // advance
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
        .onAppear {
            selection = Set(onboardingVM.interests)
        }
        // Hidden navigation link
        .background(
            NavigationLink("", isActive: $goNext) {
                CampusLifeView()
                    .environmentObject(onboardingVM)   // keep SAME VM
            }
            .hidden()

        )
    }
}

