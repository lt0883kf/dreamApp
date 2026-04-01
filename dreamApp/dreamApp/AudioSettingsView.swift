import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct AudioSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @Query private var users: [User]

    @State private var showFileImporter = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isPlaying = false
    @AppStorage("appAudioVolume") private var volume: Double = 0.5

    private let playbackService = AudioPlaybackService()

    private var currentUser: User? {
        users.first { $0.userId == currentUserId }
    }

    private var audioFiles: [AudioFile] {
        currentUser?.audioFiles ?? []
    }

    var body: some View {
        List {
            Section {
                Button {
                    showFileImporter = true
                } label: {
                    Label("音声ファイルを追加", systemImage: "plus.circle")
                }
            }

            Section("再生音量") {
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundStyle(.secondary)
                    Slider(value: $volume, in: 0...1, step: 0.01)
                        .onChange(of: volume) {
                            playbackService.applyVolume(Float(volume))
                        }
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundStyle(.secondary)
                }
                Text("\(Int(volume * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if audioFiles.isEmpty {
                Section {
                    Text("音声ファイルが登録されていません")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("登録済み音声ファイル") {
                    ForEach(audioFiles) { file in
                        AudioFileRow(
                            file: file,
                            isPlaying: isPlaying,
                            onTogglePlay: { togglePreview(file: file) },
                            onSelect: { selectFile(file) }
                        )
                    }
                    .onDelete(perform: deleteFiles)
                }
            }
        }
        .navigationTitle("音声設定")
        #if os(iOS)
        .toolbar {
            if !audioFiles.isEmpty {
                EditButton()
            }
        }
        #endif
        .onAppear {
            playbackService.onStateChanged = { [self] in
                isPlaying = playbackService.isPlaying
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.audio],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let sourceURL = urls.first else { return }
            do {
                let imported = try FileStorageService.importAudioFile(from: sourceURL)
                let audioFile = AudioFile(
                    fileName: imported.fileName,
                    fileExtension: imported.fileExtension,
                    localPath: imported.relativePath
                )
                audioFile.user = currentUser
                currentUser?.audioFiles.append(audioFile)
                modelContext.insert(audioFile)
                try modelContext.save()
            } catch {
                errorMessage = "ファイルのインポートに失敗しました: \(error.localizedDescription)"
                showError = true
            }
        case .failure(let error):
            errorMessage = "ファイルの選択に失敗しました: \(error.localizedDescription)"
            showError = true
        }
    }

    private func togglePreview(file: AudioFile) {
        if playbackService.isPlaying {
            playbackService.stop()
        } else {
            let url = FileStorageService.audioFileURL(relativePath: file.localPath)
            do {
                try playbackService.playPreview(url: url, volume: Float(volume))
            } catch {
                errorMessage = "再生に失敗しました: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func selectFile(_ file: AudioFile) {
        for f in audioFiles {
            f.isSelected = (f.id == file.id)
        }
        try? modelContext.save()
    }

    private func deleteFiles(offsets: IndexSet) {
        for index in offsets {
            let file = audioFiles[index]
            FileStorageService.deleteAudioFile(relativePath: file.localPath)
            modelContext.delete(file)
        }
        try? modelContext.save()
    }
}

struct AudioFileRow: View {
    let file: AudioFile
    let isPlaying: Bool
    let onTogglePlay: () -> Void
    let onSelect: () -> Void

    var body: some View {
        HStack {
            Button {
                onSelect()
            } label: {
                Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(file.isSelected ? .blue : .gray)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading) {
                Text(file.fileName)
                    .lineLimit(1)
                Text(".\(file.fileExtension)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onTogglePlay()
            } label: {
                Image(systemName: isPlaying ? "stop.circle" : "play.circle")
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
    }
}
