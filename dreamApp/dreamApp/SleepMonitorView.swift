import SwiftUI
import SwiftData

struct SleepMonitorView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @Query private var users: [User]

    @State private var playbackService = AudioPlaybackService()
    @State private var remPeriods: [REMPeriod] = []
    @State private var errorMessage = ""
    @State private var showError = false

    private var currentUser: User? {
        users.first { $0.userId == currentUserId }
    }

    private var selectedAudioFile: AudioFile? {
        currentUser?.audioFiles.first { $0.isSelected }
    }

    private var hasSchedule: Bool {
        currentUser?.sleepSchedule != nil
    }

    var body: some View {
        List {
            // 現在の設定サマリー
            Section("睡眠設定") {
                if let schedule = currentUser?.sleepSchedule {
                    HStack {
                        Text("就寝時間")
                        Spacer()
                        Text(formatted(schedule.bedtime))
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("起床時間")
                        Spacer()
                        Text(formatted(schedule.wakeUpTime))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("睡眠設定がされていません")
                        .foregroundStyle(.secondary)
                }
            }

            Section("再生音声") {
                if let file = selectedAudioFile {
                    HStack {
                        Image(systemName: "music.note")
                        Text(file.fileName)
                    }
                } else {
                    Text("音声ファイルが選択されていません")
                        .foregroundStyle(.secondary)
                }
            }

            // セッション操作
            Section {
                if playbackService.isSessionActive {
                    Button(role: .destructive) {
                        stopSession()
                    } label: {
                        HStack {
                            Spacer()
                            Label("睡眠セッションを停止", systemImage: "stop.circle.fill")
                            Spacer()
                        }
                    }
                } else {
                    Button {
                        startSession()
                    } label: {
                        HStack {
                            Spacer()
                            Label("睡眠セッションを開始", systemImage: "play.circle.fill")
                            Spacer()
                        }
                    }
                    .disabled(!hasSchedule || selectedAudioFile == nil)
                }
            }

            // ステータス
            if playbackService.isSessionActive {
                Section("ステータス") {
                    if let cycle = playbackService.currentREMCycleNumber {
                        HStack {
                            Image(systemName: "waveform")
                                .foregroundStyle(.blue)
                            Text("レム睡眠中（第\(cycle)周期）- 音声再生中")
                        }
                    } else {
                        HStack {
                            Image(systemName: "moon.zzz")
                                .foregroundStyle(.indigo)
                            Text("ノンレム睡眠中 - 待機中")
                        }
                    }
                }
            }

            // レム睡眠タイムライン
            if !remPeriods.isEmpty {
                Section("レム睡眠スケジュール") {
                    ForEach(remPeriods) { period in
                        HStack {
                            Circle()
                                .fill(period.cycleNumber == playbackService.currentREMCycleNumber ? .blue : .gray.opacity(0.3))
                                .frame(width: 10, height: 10)
                            Text("第\(period.cycleNumber)周期")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(formatted(period.startTime)) 〜 \(formatted(period.endTime))")
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .navigationTitle("睡眠モニター")
        .onAppear {
            calculateREMPeriods()
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func startSession() {
        guard let schedule = currentUser?.sleepSchedule,
              let audioFile = selectedAudioFile else { return }

        let times = SleepCycleService.resolveActualTimes(
            bedtime: schedule.bedtime,
            wakeUpTime: schedule.wakeUpTime
        )
        let periods = SleepCycleService.calculateREMPeriods(
            bedtime: times.actualBedtime,
            wakeUpTime: times.actualWakeUpTime
        )
        remPeriods = periods

        let audioURL = FileStorageService.audioFileURL(relativePath: audioFile.localPath)

        // セッション記録
        let session = SleepSession(
            startTime: Date(),
            actualBedtime: times.actualBedtime,
            actualWakeUpTime: times.actualWakeUpTime
        )
        session.user = currentUser
        currentUser?.sleepSessions.append(session)
        modelContext.insert(session)
        try? modelContext.save()

        do {
            try playbackService.startSleepSession(remPeriods: periods, audioURL: audioURL)
        } catch {
            errorMessage = "セッションの開始に失敗しました: \(error.localizedDescription)"
            showError = true
        }
    }

    private func stopSession() {
        playbackService.stopSleepSession()

        // アクティブなセッションを終了
        if let activeSession = currentUser?.sleepSessions.first(where: { $0.isActive }) {
            activeSession.endTime = Date()
            activeSession.isActive = false
            try? modelContext.save()
        }
    }

    private func calculateREMPeriods() {
        guard let schedule = currentUser?.sleepSchedule else { return }
        let times = SleepCycleService.resolveActualTimes(
            bedtime: schedule.bedtime,
            wakeUpTime: schedule.wakeUpTime
        )
        remPeriods = SleepCycleService.calculateREMPeriods(
            bedtime: times.actualBedtime,
            wakeUpTime: times.actualWakeUpTime
        )
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
