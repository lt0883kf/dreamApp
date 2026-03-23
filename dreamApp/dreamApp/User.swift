import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var userId: String
    var passwordHash: String
    var salt: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var sleepSchedule: SleepSchedule?
    @Relationship(deleteRule: .cascade) var audioFiles: [AudioFile]
    @Relationship(deleteRule: .cascade) var sleepSessions: [SleepSession]

    init(userId: String, passwordHash: String, salt: String) {
        self.userId = userId
        self.passwordHash = passwordHash
        self.salt = salt
        self.createdAt = Date()
        self.audioFiles = []
        self.sleepSessions = []
    }
}
