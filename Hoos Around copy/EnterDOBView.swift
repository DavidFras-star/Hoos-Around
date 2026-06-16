import SwiftUI

struct EnterDOBView: View {
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @State private var birthdate: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var navigateToConfirm = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("When’s your birthday?")
                .font(.title)
                .bold()
                .foregroundColor(.white)

            DatePicker("Birthdate", selection: $birthdate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)

            Button("Continue") {
                navigateToConfirm = true
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()

            NavigationLink(
                "",
                destination: ConfirmAgeView(birthdate: birthdate).environmentObject(onboardingVM),
                isActive: $navigateToConfirm
            )
            .opacity(0)

        }
        .padding()
        .background(LinearGradient(colors: [Color.purple, Color.black], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }
}

