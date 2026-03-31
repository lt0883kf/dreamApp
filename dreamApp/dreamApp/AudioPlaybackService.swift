import AVFoundation
import Foundation

@MainActor
final class AudioPlaybackService {
    private var audioPlayer: AVAudioPlayer?
    private var silentPlayer: AVAudioPlayer?
    private var playbackTask: Task<Void, Never>?

    private(set) var isPlaying = false
    private(set) var isSessionActive = false
    private(set) var currentREMCycleNumber: Int?

    // 状態変更時にViewに通知するコールバック
    var onStateChanged: (() -> Void)?

    func applyVolume(_ value: Float) {
        audioPlayer?.volume = value
    }

    #if os(iOS)
    func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
    }
    #else
    func configureAudioSession() throws {}
    #endif

    // MARK: - プレビュー再生

    func playPreview(url: URL, volume: Float = 1.0) throws {
        stop()
        try configureAudioSession()
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.volume = volume
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
        isPlaying = true
        onStateChanged?()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        onStateChanged?()
    }

    // MARK: - 睡眠セッション再生

    func startSleepSession(remPeriods: [REMPeriod], audioURL: URL, volume: Float = 1.0) throws {
        try configureAudioSession()
        try startSilentLoop()
        isSessionActive = true
        onStateChanged?()

        playbackTask = Task { [weak self] in
            for period in remPeriods {
                guard !Task.isCancelled else { break }

                let delayUntilREM = period.startTime.timeIntervalSinceNow
                if delayUntilREM > 0 {
                    try? await Task.sleep(for: .seconds(delayUntilREM))
                }

                guard !Task.isCancelled else { break }

                await self?.startREMAudio(url: audioURL, cycleNumber: period.cycleNumber, volume: volume)

                let remDuration = period.endTime.timeIntervalSince(period.startTime)
                if remDuration > 0 {
                    try? await Task.sleep(for: .seconds(remDuration))
                }

                guard !Task.isCancelled else { break }
                await self?.stopREMAudio()
            }

            await MainActor.run {
                self?.currentREMCycleNumber = nil
                self?.onStateChanged?()
            }
        }
    }

    func stopSleepSession() {
        playbackTask?.cancel()
        playbackTask = nil
        audioPlayer?.stop()
        audioPlayer = nil
        silentPlayer?.stop()
        silentPlayer = nil
        isPlaying = false
        isSessionActive = false
        currentREMCycleNumber = nil
        onStateChanged?()
    }

    // MARK: - Private

    private func startSilentLoop() throws {
        let sampleRate: Double = 44100
        let duration: Double = 1.0
        let numSamples = Int(sampleRate * duration)
        let silentData = generateSilentWAV(sampleRate: Int(sampleRate), numSamples: numSamples)

        silentPlayer = try AVAudioPlayer(data: silentData)
        silentPlayer?.numberOfLoops = -1
        silentPlayer?.volume = 0.01
        silentPlayer?.play()
    }

    private func startREMAudio(url: URL, cycleNumber: Int, volume: Float) {
        do {
            silentPlayer?.volume = 0
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = volume
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            currentREMCycleNumber = cycleNumber
            onStateChanged?()
        } catch {
            silentPlayer?.volume = 0.01
        }
    }

    private func stopREMAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentREMCycleNumber = nil
        silentPlayer?.volume = 0.01
        onStateChanged?()
    }

    private func generateSilentWAV(sampleRate: Int, numSamples: Int) -> Data {
        var data = Data()

        let byteRate = sampleRate * 2
        let dataSize = numSamples * 2
        let fileSize = 36 + dataSize

        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) })

        // data chunk
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })
        data.append(Data(count: dataSize))

        return data
    }
}
