import SwiftUI
import SwiftData

struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currentUserId") private var currentUserId: String = ""

    @State private var userId = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showRegistration = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("dreamApp")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
                    TextField("ユーザーID", text: $userId)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif

                    SecureField("パスワード", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 32)

                Button {
                    login()
                } label: {
                    Text("ログイン")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 32)
                .disabled(userId.isEmpty || password.isEmpty)

                Button("アカウントを作成") {
                    showRegistration = true
                }
                .padding(.top, 8)

                Spacer()
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .navigationDestination(isPresented: $showRegistration) {
                RegistrationView()
            }
        }
    }

    private func login() {
        let service = AuthenticationService(modelContext: modelContext)
        do {
            let user = try service.login(userId: userId, password: password)
            currentUserId = user.userId
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
