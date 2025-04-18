import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    var player: AVAudioPlayer?

    func playBeep() {
        playSound(named: "beep")
    }

    func playChime() {
        playSound(named: "chime")
    }

    private func playSound(named: String) {
        if let url = Bundle.main.url(forResource: named, withExtension: "wav") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.play()
        }
    }
}

