import Foundation
import AVFoundation

@Observable
final class AudioManager {
    private var loFiPlayer: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()
    var isMuted = false

    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    func playLoFi() {
        guard let url = Bundle.main.url(forResource: "lofi-beat", withExtension: "mp3") else {
            print("lofi-beat.mp3 not found in bundle")
            return
        }
        do {
            loFiPlayer = try AVAudioPlayer(contentsOf: url)
            loFiPlayer?.numberOfLoops = -1
            loFiPlayer?.volume = isMuted ? 0 : 0.3
            loFiPlayer?.play()
        } catch {
            print("Lo-fi playback failed: \(error)")
        }
    }

    func stopLoFi() {
        loFiPlayer?.stop()
    }

    func toggleMute() {
        isMuted.toggle()
        loFiPlayer?.volume = isMuted ? 0 : 0.3
    }

    func speakDJ(_ script: String) {
        let utterance = AVSpeechUtterance(string: script)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.45
        utterance.pitchMultiplier = 0.9
        synthesizer.speak(utterance)
    }
}
