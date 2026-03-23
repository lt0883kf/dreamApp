import Foundation
import SwiftData

enum AuthError: LocalizedError {
    case userIdAlreadyExists
    case invalidCredentials
    case userNotFound
    case passwordTooShort
    case userIdTooShort

    var errorDescription: String? {
        switch self {
        case .userIdAlreadyExists:
            return "このIDは既に使用されています"
        case .invalidCredentials:
            return "IDまたはパスワードが正しくありません"
        case .userNotFound:
            return "ユーザーが見つかりません"
        case .passwordTooShort:
            return "パスワードは6文字以上で入力してください"
        case .userIdTooShort:
            return "IDは3文字以上で入力してください"
        }
    }
}

@MainActor
final class AuthenticationService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func register(userId: String, password: String) throws -> User {
        let trimmedId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedId.count >= 3 else { throw AuthError.userIdTooShort }
        guard password.count >= 6 else { throw AuthError.passwordTooShort }

        let predicate = #Predicate<User> { $0.userId == trimmedId }
        let descriptor = FetchDescriptor<User>(predicate: predicate)
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else { throw AuthError.userIdAlreadyExists }

        let salt = PasswordHasher.generateSalt()
        let hash = PasswordHasher.hash(password: password, salt: salt)
        let user = User(userId: trimmedId, passwordHash: hash, salt: salt)
        modelContext.insert(user)
        try modelContext.save()
        return user
    }

    func login(userId: String, password: String) throws -> User {
        let trimmedId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        let predicate = #Predicate<User> { $0.userId == trimmedId }
        let descriptor = FetchDescriptor<User>(predicate: predicate)
        let users = try modelContext.fetch(descriptor)
        guard let user = users.first else { throw AuthError.invalidCredentials }

        guard PasswordHasher.verify(password: password, salt: user.salt, hash: user.passwordHash) else {
            throw AuthError.invalidCredentials
        }
        return user
    }
}
