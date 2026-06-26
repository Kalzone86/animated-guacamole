import AVFoundation
import Combine

class SoundManager: NSObject, ObservableObject {
    @Published var currentlyPlayingId: String? = nil
    private var player: AVAudioPlayer?

    override init() {
        super.init()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    func toggle(sound: Sound) {
        if currentlyPlayingId == sound.id {
            stop()
        } else {
            play(sound: sound)
        }
    }

    private func play(sound: Sound) {
        // Files live in the "sounds" folder reference inside the bundle
        let url = Bundle.main.url(forResource: sound.filename, withExtension: "mp3", subdirectory: "sounds")
               ?? Bundle.main.url(forResource: sound.filename, withExtension: "mp3")
        guard let url else {
            print("Missing sound file: \(sound.filename).mp3")
            return
        }
        player?.stop()
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
            currentlyPlayingId = sound.id
        } catch {
            print("Playback error: \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        currentlyPlayingId = nil
    }
}

extension SoundManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.currentlyPlayingId = nil }
    }
}
