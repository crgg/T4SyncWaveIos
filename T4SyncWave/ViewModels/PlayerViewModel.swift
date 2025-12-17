import Foundation
import Combine

@MainActor
final class PlayerViewModel: ObservableObject,
                             WebRTCPlaybackDelegate,
                             WebRTCRoleDelegate {

    // MARK: - Dependencies
    let audio = AudioPlayerManager.shared
    let rtc = WebRTCManager.shared

    // MARK: - UI State
    @Published var isHost: Bool
    @Published var syncStatus: String = "Synced"
    @Published var users: [UserPresence] = []
    @Published var currentTrack: AudioTrack?

    // MARK: - Room info
    let roomId: String
    let userName: String

    // MARK: - Timer (re-sync)
    private var syncTimer: Timer?

    // MARK: - Init
    init(
        roomId: String = "room91",
        userName: String = "Ramon23",
        isHost: Bool = true
    ) {
        
        
        self.roomId = roomId
        self.userName = userName
        self.isHost = isHost
        PlaybackSyncService.shared.isHost = isHost
        PlaybackSyncService.shared.roomId = roomId

        // Delegates
        rtc.playbackDelegate = self
        
        rtc.roleDelegate = self

        // 1️⃣ Conectar signaling
        WebSocketSignaling.shared.connect(
            room: roomId,
            userName: userName
        )
        //
        if isHost {
            let url = URL(string:
                            "https://go2storage.s3.us-east-2.amazonaws.com/audio/5e8f893d-43a4-43c6-82ae-5f801126d559.mp3"
            )!
            audio.loadRemote(url: url, title: "demo")
        }
   
//         3️⃣ Cargar audio local (MP3 de prueba)
//        audio.load(mp3Name: "demo")

        // 4️⃣ Timer de re-sync (solo host)
        startSyncTimer()
    }
    
    func togglePlay() {
        if audio.isPlaying {
            audio.pause()
        } else {
            audio.play()
        }
        
        if isHost {
            if audio.isReadyToPlay {
                broadcast()
            }
        }
    }

    deinit {
        syncTimer?.invalidate()
    }

    // MARK: - Playback controls (HOST ONLY)

    func playPause() {
        guard isHost else { return }

        if audio.isPlaying {
            audio.pause()
        } else {
            audio.play()
        }

        broadcastState()
    }
    private func broadcast() {
        rtc.sendPlayback(
              roomId: roomId,
              trackURL: audio.currentURL!,
              position: audio.currentTime,
              isPlaying: audio.isPlaying
          )
      }
    func seek(to value: Double) {
        guard isHost else { return }

        audio.seek(to: value)
        broadcastState()
    }

    // MARK: - WebRTCPlaybackDelegate

    /// 🔴 AQUÍ VA didReceivePlayback
    func didReceivePlayback(_ state: PlaybackState) {
        
        
        guard !isHost else { return }
        
        
        // 🔑 Cargar MP3 remoto ANTES de play
        if audio.currentURL?.absoluteString != state.trackUrl {
            let url = URL(string: state.trackUrl)!
            audio.loadRemote(url: url, title: "remote")
        }

//        let localTime = audio.syncTime()
//        let diff = abs(localTime - state.position)

//        syncStatus = diff < 1 ? "Synced" : "Adjusting…"
//
//        if diff > 1 {
//            audio.seek(to: state.position)
//        }

//        state.isPlaying ? audio.play() : audio.pause()
        audio.seek(to: state.position)
        
        if state.isPlaying {
            audio.play()
        } else {
            audio.pause()
        }
    }

    // MARK: - WebRTCRoleDelegate

    func didReceiveRole(_ role: String) {
        isHost = (role == "host")
        print("👑 Rol asignado:", role)
    }

    // MARK: - Broadcast playback state (HOST)

    func broadcastState() {
        guard isHost else { return }

//        let position = audio.syncTime()
        let playing = audio.isPlaying

        print("📤 Enviando playback-state vía WebSocket.  , playing=\(playing)")

        WebSocketSignaling.shared.send([
            "type": "playback-state",
            "room": roomId,
//            "position": position,
            "isPlaying": playing,
            "timestamp": Int(Date().timeIntervalSince1970)
        ])
    }


    // MARK: - Re-sync timer

    private func startSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
              guard let self,
                    self.isHost,
                    self.audio.isReadyToPlay,
                    self.audio.isPlaying else { return }

              self.broadcast()
          }
    }
    
   
}

