import Foundation
import SwiftData

@Model
final class AudioFile {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var fileExtension: String
    var localPath: String
    var addedAt: Date
    var isSelected: Bool

    var user: User?

    init(fileName: String, fileExtension: String, localPath: String) {
        self.id = UUID()
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.localPath = localPath
        self.addedAt = Date()
        self.isSelected = false
    }
}
