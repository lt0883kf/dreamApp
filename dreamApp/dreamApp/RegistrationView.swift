import SwiftUI
import SwiftData

struct RegistrationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var userId = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("アカウント作成")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                TextField("ユーザーID（3文字以上）", text: $userId)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif

                SecureField("パスワード（6文字以上）", text: $password)
                    .textFieldStyle(.roundedBorder)

                SecureField("パスワード（確認）", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 32)

            Button {
                register()
            } label: {
                Text("登録")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .disabled(userId.isEmpty || password.isEmpty || confirmPassword.isEmpty)

            Spacer()
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .alert("登録完了", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("アカウントが作成されました。ログインしてください。")
        }
    }

    private func register() {
        guard password == confirmPassword else {
            errorMessage = "パスワードが一致しません"
            showError = true
            return
        }

        let service = AuthenticationService(modelContext: modelContext)
        do {
            _ = try service.register(userId: userId, password: password)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
