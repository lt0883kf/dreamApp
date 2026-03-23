import Foundation
import CryptoKit

enum PasswordHasher {
    static func generateSalt() -> String {
        let saltData = (0..<32).map { _ in UInt8.random(in: 0...255) }
        return Data(saltData).base64EncodedString()
    }

    static func hash(password: String, salt: String) -> String {
        let combined = password + salt
        let digest = SHA256.hash(data: Data(combined.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func verify(password: String, salt: String, hash: String) -> Bool {
        return self.hash(password: password, salt: salt) == hash
    }
}
