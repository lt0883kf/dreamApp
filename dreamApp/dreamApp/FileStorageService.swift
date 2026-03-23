import Foundation

enum FileStorageService {
    static let audioDirectoryName = "Audio"

    static func audioDirectory() throws -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioDir = documentsURL.appendingPathComponent(audioDirectoryName)
        if !FileManager.default.fileExists(atPath: audioDir.path) {
            try FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)
        }
        return audioDir
    }

    /// セキュリティスコープ付きURLからアプリサンドボックスにコピー
    static func importAudioFile(from sourceURL: URL) throws -> (fileName: String, fileExtension: String, relativePath: String) {
        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessing { sourceURL.stopAccessingSecurityScopedResource() } }

        let audioDir = try audioDirectory()
        let ext = sourceURL.pathExtension
        let uniqueName = UUID().uuidString + "." + ext
        let destinationURL = audioDir.appendingPathComponent(uniqueName)
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        return (
            fileName: sourceURL.deletingPathExtension().lastPathComponent,
            fileExtension: ext,
            relativePath: "\(audioDirectoryName)/\(uniqueName)"
        )
    }

    /// 相対パスから実際のファイルURLを取得
    static func audioFileURL(relativePath: String) -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(relativePath)
    }

    /// ファイルを削除
    static func deleteAudioFile(relativePath: String) {
        let url = audioFileURL(relativePath: relativePath)
        try? FileManager.default.removeItem(at: url)
    }
}
