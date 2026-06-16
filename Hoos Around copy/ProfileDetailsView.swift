import SwiftUI

struct ProfileDetailsView: View {
    // Add at top of ProfileDetailsView
    private let defaultProfileImage = UIImage(named: "defaultProfile")
    @EnvironmentObject var onboardingVM: OnboardingViewModel

    @State private var majorSearch: String = ""
    @State private var selectedMajor: String = ""
    @State private var selectedYear: String = ""
    @State private var goToPreview = false

    // NEW: profile photo picker sheet
    @State private var isPhotoPickerPresented = false

    // List of class years
    static let classYears = [
        "Freshman", "Sophomore", "Junior", "Senior", "Graduate Student", "Other"
    ]

    // List of majors by category
    static let majors: [(category: String, options: [String])] = [
        ("STEM", [
            "Biology", "Chemistry", "Physics", "Mathematics", "Applied Mathematics", "Statistics", "Environmental Science",
            "Computer Science", "Data Science", "Information Technology", "Cybersecurity",
            "Mechanical Engineering", "Civil Engineering", "Electrical Engineering", "Computer Engineering",
            "Chemical Engineering", "Biomedical Engineering", "Industrial Engineering", "Aerospace Engineering", "Environmental Engineering"
        ]),
        ("Business, Finance, and Management", [
            "Business Administration", "Accounting", "Finance", "Marketing", "Management", "Management Information Systems (MIS)",
            "Entrepreneurship", "Supply Chain Management", "Hospitality Management", "International Business",
            "Human Resources Management", "Real Estate"
        ]),
        ("Social Sciences & Psychology", [
            "Psychology", "Sociology", "Anthropology", "Political Science", "Economics", "International Relations",
            "Criminology", "Public Policy", "Human Development & Family Studies", "Social Work"
        ]),
        ("Humanities", [
            "English Language & Literature", "History", "Philosophy", "Religious Studies", "Linguistics", "Classics",
            "Comparative Literature", "American Studies", "Gender & Women’s Studies", "African American Studies",
            "Latin American Studies", "Asian Studies", "Middle Eastern Studies"
        ]),
        ("Communication, Media, and Arts", [
            "Communication Studies", "Journalism", "Media Studies", "Film & Television", "Public Relations",
            "Advertising", "Graphic Design", "Studio Art", "Art History", "Photography", "Theater", "Music",
            "Dance", "Digital Media"
        ]),
        ("Interdisciplinary & Emerging Fields", [
            "Cognitive Science", "Neuroscience", "Environmental Studies", "Global Studies", "Peace & Conflict Studies",
            "Urban Studies", "Liberal Studies", "Education Studies", "Science, Technology & Society", "Sustainability Studies"
        ]),
        ("Health & Medical Fields", [
            "Nursing", "Public Health", "Kinesiology / Exercise Science", "Health Sciences", "Nutrition / Dietetics",
            "Speech Pathology", "Occupational Therapy (Pre-OT track)", "Physical Therapy (Pre-PT track)", "Athletic Training"
        ]),
        ("Education & Human Services", [
            "Elementary Education", "Secondary Education", "Special Education", "Early Childhood Education",
            "Educational Psychology", "Counseling / School Counseling", "Youth & Community Development"
        ]),
        ("Applied & Professional Majors", [
            "Architecture", "Construction Management", "Criminal Justice", "Forensic Science", "Fashion Merchandising / Apparel Design"
        ])
    ]

    // Computed property for filtering majors
    var filteredMajors: [(category: String, majors: [String])] {
        if majorSearch.isEmpty {
            return Self.majors.map { (category: $0.category, majors: $0.options) }
        }
        let lowerSearch = majorSearch.lowercased()
        return Self.majors.compactMap { group in
            let filtered = group.options.filter { $0.lowercased().contains(lowerSearch) }
            if filtered.isEmpty { return nil }
            return (category: group.category, majors: filtered)
        }
    }

    var body: some View {
        VStack(spacing: 28) {
            Text("Complete Your Profile")
                .font(.largeTitle).bold()
                .foregroundColor(.white)
                .padding(.top, 30)

            VStack(spacing: 20) {

                // 🔹 PROFILE PHOTO PICKER SECTION
                // PROFILE PHOTO PICKER SECTION
                VStack(spacing: 8) {
                    Text("Profile Photo")
                        .font(.headline)
                        .foregroundColor(.white)

                    Button {
                        isPhotoPickerPresented = true
                    } label: {
                        if let avatar = onboardingVM.profileAvatar ?? defaultProfileImage {
                            Image(uiImage: avatar)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                .shadow(radius: 6)
                                .padding(.top, 20)
                        } else {
                            // Placeholder circle
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 120, height: 120)

                                VStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.title2.bold())
                                        .foregroundColor(.white)

                                    Text("Add profile photo")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            .padding(.top, 20)
                        }
                    }
                    .buttonStyle(.plain)
                }


                // 🔹 MAJOR PICKER + SEARCH
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Major")
                            .font(.headline)
                            .foregroundColor(.white)

                        TextField("Search or select major...", text: $majorSearch)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: majorSearch) { val in
                                if val.isEmpty, !selectedMajor.isEmpty {
                                    majorSearch = selectedMajor
                                }
                            }

                        ScrollView(.vertical, showsIndicators: true) {
                            ForEach(filteredMajors, id: \.category) { group in
                                if !group.majors.isEmpty {
                                    Text(group.category)
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                        .padding(.vertical, 2)

                                    ForEach(group.majors, id: \.self) { major in
                                        Button {
                                            selectedMajor = major
                                            majorSearch = major
                                        } label: {
                                            HStack {
                                                Text(major).foregroundColor(.black)
                                                Spacer()
                                                if selectedMajor == major {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.purple)
                                                }
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 160)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.bottom, 4)
                    }

                    // 🔹 YEAR / CLASS PICKER
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Class Year")
                            .font(.headline)
                            .foregroundColor(.white)

                        Picker("Select year", selection: $selectedYear) {
                            ForEach(Self.classYears, id: \.self) { year in
                                Text(year).tag(year)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            Button {
                onboardingVM.major = selectedMajor
                onboardingVM.year  = selectedYear
                goToPreview = true
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.purple)
                    .cornerRadius(16)
            }
            .disabled(selectedMajor.isEmpty || selectedYear.isEmpty)
            .padding(.bottom, 16)
        }
        // Navigate to ProfilePreviewView
        .navigationDestination(isPresented: $goToPreview) {
            ProfilePreviewView()
                .environmentObject(onboardingVM)
        }
        .onAppear {
            let defaultMajor = onboardingVM.major.isEmpty
                ? (Self.majors.first?.options.first ?? "")
                : onboardingVM.major
            let defaultYear = onboardingVM.year.isEmpty
                ? (Self.classYears.first ?? "")
                : onboardingVM.year

            selectedMajor = defaultMajor
            selectedYear  = defaultYear

            if majorSearch.isEmpty { majorSearch = defaultMajor }
        }
        .sheet(isPresented: $isPhotoPickerPresented) {
            ImagePicker { picked in
                if let picked = picked {
                    switch picked {
                    case .photo(let img):
                        onboardingVM.profileAvatar = img
                    }
                }

                isPhotoPickerPresented = false

            }
        }


        .background(
            LinearGradient(colors: [Color.purple, Color.purple.opacity(0.6)],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        )
    }
}

