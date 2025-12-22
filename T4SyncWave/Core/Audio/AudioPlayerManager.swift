import Foundation
import AVFoundation
import MediaPlayer
import Combine

@MainActor
final class AudioPlayerManager: NSObject,  ObservableObject {

    static let shared = AudioPlayerManager()
    
    
    private var timeObserverToken: Any?

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var audioSessionConfigured = false
    
   
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var isReadyToPlay: Bool = false
    @Published var isRepeatEnabled: Bool = false  // 🔁 Modo repetir
    public var currentURL: URL?
    
    private var shouldAutoPlay = false


    override init() {
        super.init()
        configureAudioSessionOnce()
        setupRemoteCommands()
        setupEndOfPlaybackObserver()
    }
    
    // MARK: - End of Playback Observer
    private func setupEndOfPlaybackObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    @objc private func playerDidFinishPlaying() {
        Task { @MainActor in
            print("🏁 Música terminada")
            
            if isRepeatEnabled {
                // Repetir: reiniciar y seguir reproduciendo
                print("🔁 Repitiendo...")
                seek(to: 0)
                currentTime = 0
                player?.play()
            } else {
                // No repetir: pausar y quedarse al final
                isPlaying = false
                updatePlaybackRate(0.0)
                // Notificar que terminó
                NotificationCenter.default.post(name: .audioDidFinishPlaying, object: nil)
            }
        }
    }
    
    func toggleRepeat() {
        isRepeatEnabled.toggle()
        print("🔁 Repeat: \(isRepeatEnabled ? "ON" : "OFF")")
    }

    // MARK: - Audio Session (UNA VEZ)
    private func configureAudioSessionOnce() {
        guard !audioSessionConfigured else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            audioSessionConfigured = true
            print("🔊 AudioSession configurada")
        } catch {
            print("❌ AudioSession error:", error)
        }
    }

    private func activateSessionIfNeeded() {
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - Load Remote MP3 (S3)
    func loadRemote(url: URL, title: String) {
        if currentURL == url {
            print("ℹ️ Track ya cargado")
            return
        }
        
        // Limpiar player anterior ANTES de crear uno nuevo
        cleanupCurrentPlayer()

        // Reset estado
        isReadyToPlay = false
        currentTime = 0
        
        currentURL = url
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        
        observePlaybackTime()
        item.addObserver(
            self,
            forKeyPath: "status",
            options: [.new, .initial],
            context: nil
        )
        
        updateNowPlaying(title: title)
        print("🎧 MP3 remoto cargado")
    }
    
    /// Limpia el player actual y sus observers
    private func cleanupCurrentPlayer() {
        // Remover time observer del player ACTUAL (antes de reemplazarlo)
        if let token = timeObserverToken, let currentPlayer = player {
            currentPlayer.removeTimeObserver(token)
            timeObserverToken = nil
        }
        
        // Remover KVO observer del item actual
        if let currentItem = player?.currentItem {
            currentItem.removeObserver(self, forKeyPath: "status")
        }
        
        // Pausar y limpiar
        player?.pause()
    }

    // MARK: - Play / Pause
    func play() {
        guard player != nil else {
            print("❌ play() sin player")
            return
        }
        
        shouldAutoPlay = true
        activateSessionIfNeeded()
        if !isReadyToPlay {
            print("⏳ play() solicitado, esperando readyToPlay")
            return
        }
        
        // Si la música terminó (currentTime >= duration - 0.5), reiniciar al principio
        if duration > 0 && currentTime >= duration - 0.5 {
            print("🔄 Música terminada, reiniciando al principio")
            seek(to: 0)
            currentTime = 0
        }
        
        // 🔥 SOLO si ya está listo
        player?.play()
        isPlaying = true
        updatePlaybackRate(1.0)
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updatePlaybackRate(0.0)
    }
    
    /// Set volume (0.0 = muted, 1.0 = full volume)
    func setVolume(_ volume: Float) {
        player?.volume = volume
    }

    // MARK: - Seek
    func seek(to time: Double) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }

    // MARK: - Observers
    private func observeTime() {
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 600),
            queue: .main
        ) {  time in
            print("🕒 1 \(time.seconds)")
            Task { @MainActor in
                self.currentTime = time.seconds
                self.updateElapsedTime(time.seconds)
            }
        }
    }

    private func observeDuration(item: AVPlayerItem) {
        item.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async {
                self.duration = item.asset.duration.seconds
            }
        }
    }

    // MARK: - Now Playing
    private func updateNowPlaying(title: String) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: title
        ]
    }

    private func updateElapsedTime(_ time: Double) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
    }

    private func updatePlaybackRate(_ rate: Float) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = rate
    }

    // MARK: - Lock Screen Controls
    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: event.positionTime)
            return .success
        }
    }
    
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "status",
              let item = object as? AVPlayerItem else { return }

        switch item.status {

        case .readyToPlay:
            print("✅ AVPlayerItem readyToPlay")
            isReadyToPlay = true
            if shouldAutoPlay {
                player?.play()
                isPlaying = true
                updatePlaybackRate(1.0)
                shouldAutoPlay = false
                print("▶️ AVPlayer.play()")
            }

        case .failed:
            print("❌ AVPlayerItem failed:", item.error?.localizedDescription ?? "unknown")

        default:
            break
        }
    }
    
    private func observePlaybackTime() {
        guard let player = player else { return }

        // El token ya debería estar limpio desde cleanupCurrentPlayer()
        // pero por seguridad verificamos
        if timeObserverToken != nil {
            print("⚠️ timeObserverToken no estaba limpio")
            timeObserverToken = nil
        }

        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)

        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = time.seconds
            }
        }
    }


}

