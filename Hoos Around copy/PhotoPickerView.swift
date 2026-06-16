import SwiftUI

struct PhotoPickerView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel

    // Track selected index and navigation
    @State private var selectedIndex: Int = 0
    @State private var showDetails = false

    // Active sheet for picker or cropper
    private enum ActiveSheet: Identifiable {
        case picker(index: Int)
        case cropper(image: UIImage, index: Int)

        var id: String {
            switch self {
            case .picker(let index): return "picker-\(index)"
            case .cropper(_, let index): return "cropper-\(index)"
            }
        }
    }
    @State private var activeSheet: ActiveSheet? = nil

    private var selectedCount: Int {
        onboardingVM.profilePhotos.compactMap { $0 }.count
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 8)

            Text("Add photos so people recognize you IRL")
                .font(.title2).fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal, 12)

            Text("Please add 4 photos to continue.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Group {
                if let img = onboardingVM.profilePhotos[selectedIndex] {
                    ZStack(alignment: .bottom) {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 220, height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(radius: 10)
                            .transition(.scale)

                        replaceButton
                    }
                } else {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 220, height: 220)
                        .overlay(
                            Image(systemName: "person.crop.square")
                                .font(.system(size: 56, weight: .light))
                                .foregroundColor(.white.opacity(0.3))
                        )
                        .padding(.bottom, 2)
                }
            }
            .animation(.easeInOut, value: selectedIndex)

            // Thumbnail grid
            HStack(spacing: 18) {
                ForEach(0..<4) { i in
                    Button {
                        selectedIndex = i
                        activeSheet = .picker(index: i)
                    } label: {
                        if let img = onboardingVM.profilePhotos[i] {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))

                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(width: 80, height: 80)
                        }
                    }
                }
            }
            .padding(.top, 4)

            Text("\(selectedCount)/4 selected")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Button {
                showDetails = true
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedCount == 4 ? Color.white : Color.gray.opacity(0.3))
                    .foregroundColor(.purple)
                    .cornerRadius(16)
            }
            .disabled(selectedCount != 4)
            .padding(.horizontal)
            .padding(.bottom, 12)

            NavigationLink(
                destination: ProfileDetailsView().environmentObject(onboardingVM),
                isActive: $showDetails
            ) { EmptyView() }.hidden()
        }
        .padding(.top)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.black]),
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .picker(let index):

                // OPEN PICKER
                ImagePicker { picked in
                    guard let picked = picked else {
                        activeSheet = nil
                        return
                    }

                    switch picked {
                    case .photo(let img):
                        // → go to cropping, DO NOT assign directly
                        activeSheet = .cropper(image: img, index: index)
                    }
                }

            case .cropper(let sourceImage, let index):

                // OPEN CROPPER
                ImageCropperView(
                    image: sourceImage,
                    aspectRatio: 1.0,
                    cornerRadius: 24,
                    onCancel: { activeSheet = nil },
                    onCrop: { cropped in
                        onboardingVM.profilePhotos[index] = cropped
                        activeSheet = nil
                    }
                )
                .ignoresSafeArea()
            }
        }

    }

    // Replace button
    private var replaceButton: some View {
        Button {
            activeSheet = .picker(index: selectedIndex)
        } label: {
            Text("Replace")
                .font(.subheadline).fontWeight(.semibold)
                .padding(.vertical, 8)
                .padding(.horizontal, 28)
                .background(Color.white.opacity(0.9))
                .foregroundColor(.purple)
                .cornerRadius(18)
                .shadow(radius: 3)
        }
        .padding(.bottom, 10)
    }
}
