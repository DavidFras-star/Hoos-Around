import SwiftUI
import FirebaseStorage
import FirebaseAuth

struct EditVibeView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var summaryText: String
    @State private var selectedMajor: String
    @State private var selectedYear: String
    @State private var orgs: String
    @State private var photos: [UIImage?]
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var majorSearch: String = ""
    @FocusState private var summaryFocused: Bool

    @State private var originalPhotoUrls: [String] = []
    @State private var didHydrateFromUrls = false

    // Parent-owned picker callback
    let openPhotoPicker: (Int) -> Void

    let years = ["Freshman", "Sophomore", "Junior", "Senior", "Grad Student"]

    let majors: [(category: String, options: [String])] = [/* ... */]

    var filteredMajors: [(category: String, majors: [String])] {
        if majorSearch.isEmpty {
            return majors.map { (category: $0.category, majors: $0.options) }
        }
        let lower = majorSearch.lowercased()
        return majors.compactMap { group in
            let filtered = group.options.filter { $0.lowercased().contains(lower) }
            return filtered.isEmpty ? nil : (category: group.category, majors: filtered)
        }
    }

    init(vm: OnboardingViewModel, openPhotoPicker: @escaping (Int) -> Void) {
        self.openPhotoPicker = openPhotoPicker

        let defaultMajor = vm.major.isEmpty ? vm.majors.first!.options.first! : vm.major
        let defaultYear  = vm.year.isEmpty  ? vm.years.first!                 : vm.year

        _summaryText   = State(initialValue: vm.summaryText)
        _selectedMajor = State(initialValue: defaultMajor)
        _selectedYear  = State(initialValue: defaultYear)
        _orgs          = State(initialValue: vm.orgs)

        var padded = Array(vm.profilePhotos.prefix(4))
        while padded.count < 4 { padded.append(nil) }
        _photos = State(initialValue: padded)
    }

    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        Text("Edit Your Vibe")
                            .font(.title).fontWeight(.bold)
                            .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vibe Description").font(.headline)
                            TextEditor(text: $summaryText)
                                .frame(height: 100)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                                .focused($summaryFocused)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Campus Tags").font(.headline)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Major")
                                    .font(.subheadline).foregroundColor(.secondary)

                                TextField("Search majors", text: $majorSearch)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .padding(10)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(10)

                                let allMajors = onboardingVM.majors.flatMap { $0.options }
                                let filtered  = majorSearch.isEmpty
                                    ? allMajors
                                    : allMajors.filter { $0.localizedCaseInsensitiveContains(majorSearch) }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(filtered.isEmpty ? allMajors : filtered, id: \.self) { m in
                                            Button {
                                                selectedMajor = m
                                            } label: {
                                                Text(m)
                                                    .font(.footnote)
                                                    .padding(.vertical, 6).padding(.horizontal, 10)
                                                    .background(selectedMajor == m ? Color.purple.opacity(0.2) : Color.gray.opacity(0.15))
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Year")
                                    .font(.subheadline).foregroundColor(.secondary)
                                Picker("", selection: $selectedYear) {
                                    ForEach(onboardingVM.years, id: \.self) { y in
                                        Text(y).tag(y)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Clubs / Orgs")
                                    .font(.subheadline).foregroundColor(.secondary)
                                TextField("Ex: Black Student Alliance; Club Tennis", text: $orgs, axis: .vertical)
                                    .lineLimit(1...3)
                                    .padding(10)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(10)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Profile Photos").font(.headline)
                            HStack(spacing: 12) {
                                ForEach(0..<4, id: \.self) { idx in
                                    ZStack {
                                        if idx < photos.count, let img = photos[idx] {
                                            Image(uiImage: img)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .onTapGesture {
                                                    summaryFocused = false
                                                    endEditing()
                                                    openPhotoPicker(idx) // <- parent presents
                                                }
                                        } else {
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray.opacity(0.5))
                                                .frame(width: 60, height: 60)
                                                .overlay(
                                                    Image(systemName: "plus")
                                                        .font(.title2)
                                                        .foregroundColor(.gray)
                                                )
                                                .onTapGesture {
                                                    summaryFocused = false
                                                    endEditing()
                                                    openPhotoPicker(idx) // <- parent presents
                                                }
                                        }
                                    }
                                }
                            }
                        }

                        if let error = errorMessage {
                            Text(error).foregroundColor(.red)
                        }

                        HStack {
                            Button("Cancel") { dismiss() }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)

                            Button("Save Changes") { saveChanges() }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .disabled(isSaving || selectedMajor.isEmpty || selectedYear.isEmpty)
                        }
                        .padding(.vertical, 16)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.immediately)
                .gesture(TapGesture().onEnded { summaryFocused = false; endEditing() })
                .navigationBarHidden(true)
            }
        }
        .onAppear {
            print("👁️ [EditVibeView] appeared at", Date())
        }
        .onDisappear {
            print("🚪 [EditVibeView] disappeared at", Date())
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(NotificationCenter.default.publisher(for: .editVibeDidPickImage)) { note in
            guard
                let userInfo = note.userInfo,
                let slot = userInfo["slot"] as? Int,
                let img  = userInfo["image"] as? UIImage
            else { return }

            var updated = photos
            if slot < updated.count { updated[slot] = img }
            photos = updated
            print("✅ [EditVibeView] applied image to slot \(slot) at", Date())
        }
        .onAppear {
            guard !didHydrateFromUrls else { return }
            originalPhotoUrls = onboardingVM.photoUrls

            if photos.allSatisfy({ $0 == nil }) && !originalPhotoUrls.isEmpty {
                Task {
                    var hydrated = photos
                    for (i, urlString) in originalPhotoUrls.enumerated() where i < hydrated.count {
                        guard let url = URL(string: urlString) else { continue }
                        if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                            hydrated[i] = img
                        }
                    }
                    photos = hydrated
                    didHydrateFromUrls = true
                }
            } else {
                didHydrateFromUrls = true
            }
        }
    }

    private func endEditing() {
        print("🛑 Calling UIApplication.shared.sendAction to resign first responder")
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }

    private func saveChanges() {
        isSaving = true
        errorMessage = nil

        guard let userId = Auth.auth().currentUser?.uid else {
            isSaving = false
            errorMessage = "No user ID found."
            return
        }

        var local = Array(photos.prefix(4))
        while local.count < 4 { local.append(nil) }

        let currentOriginal = originalPhotoUrls + Array(repeating: "", count: max(0, 4 - originalPhotoUrls.count))
        var finalUrls = Array(repeating: "", count: 4)

        func uploadImage(_ image: UIImage, index: Int, completion: @escaping (Result<String, Error>) -> Void) {
            let ref = Storage.storage().reference().child("profilePhotos/\(userId)/photo\(index).jpg")
            guard let data = image.jpegData(compressionQuality: 0.86) else {
                return completion(.failure(NSError(domain: "Image", code: -1,
                                                   userInfo: [NSLocalizedDescriptionKey: "JPEG encode failed"])))
            }
            let meta = StorageMetadata(); meta.contentType = "image/jpeg"
            ref.putData(data, metadata: meta) { _, err in
                if let err = err { return completion(.failure(err)) }
                ref.downloadURL { url, err in
                    if let err = err { return completion(.failure(err)) }
                    completion(.success(url?.absoluteString ?? ""))
                }
            }
        }

        let group = DispatchGroup()
        var uploadError: Error?

        for idx in 0..<4 {
            if let img = local[idx] {
                group.enter()
                uploadImage(img, index: idx) { result in
                    switch result {
                    case .success(let url): finalUrls[idx] = url
                    case .failure(let err): uploadError = err
                    }
                    group.leave()
                }
            } else {
                finalUrls[idx] = currentOriginal[idx]
            }
        }

        group.notify(queue: .main) {
            if let err = uploadError {
                isSaving = false
                errorMessage = err.localizedDescription
                return
            }

            let cleaned = finalUrls.filter { !$0.isEmpty }
            let data: [String: Any] = [
                "vibeSummary": summaryText,
                "major": selectedMajor,
                "year": selectedYear,
                "orgs": orgs,
                "photoUrls": cleaned
            ]

            FirebaseManager.shared.saveUserProfile(uid: userId, data: data) { res in
                isSaving = false
                switch res {
                case .success:
                    onboardingVM.photoUrls   = cleaned
                    onboardingVM.major       = selectedMajor
                    onboardingVM.year        = selectedYear
                    onboardingVM.orgs        = orgs
                    onboardingVM.summaryText = summaryText
                    dismiss()
                case .failure(let e):
                    errorMessage = e.localizedDescription
                }
            }
        }
    }
}
