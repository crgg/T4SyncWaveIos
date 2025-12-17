import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

@MainActor
final class LibraryViewModel: NSObject,  ObservableObject, WebRTCPlaybackDelegate,  WebRTCRoleDelegate {

   
    // MARK: - Timer (re-sync)
    private var syncTimer: Timer?
    let audio = AudioPlayerManager.shared
    let rtc = WebRTCManager.shared
    
    // MARK: - UI State
    @Published var tracks: [AudioTrack] = []
    @Published var selectedTrack: AudioTrack?
    @Published var isHost: Bool = true
    @Published var status: String = "Idle"
    
    // MARK: - Room / Role
    let roomId: String
    let userName: String
    
    private var playbackTimer: Timer?

    

    private let baseURL = URL(string: "https://t4videocall.t4ever.com")!
    
    // MARK: - Init
    init(roomId: String = "bulla4", userName : String = "Ramon") {
        self.roomId = roomId
        self.userName = userName
        
        // Connect signaling
        WebSocketSignaling.shared.connect(
            room: roomId,
            userName: userName
        )
        // Load library
        super.init( )
        // Load library
        Task {
            await loadLibrary()
        }
        rtc.playbackDelegate = self
        rtc.roleDelegate = self
    }

    // MARK: - Library
    func loadLibrary() async {
        let url = baseURL.appendingPathComponent("/api/audio/list")
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            tracks = try JSONDecoder().decode([AudioTrack].self, from: data)
            print("📚 Library cargada:", tracks.count)
        } catch {
            print("❌ Error cargando library:", error)
        }
    }

    // MARK: - User Actions

    /// ▶️ Seleccionar y reproducir (HOST)
    func select(_ track: AudioTrack) {
        
        guard isHost else { return }
        if selectedTrack == track {
            self.togglePlay()
            return
        }
        
        selectedTrack = track
        
        print("🎧 Track seleccionado:", track.title)
        
        let url = URL(string: track.url)!
        // load te audio
        audio.loadRemote(url: url, title: track.title)
        
        // start play
        audio.play()
        startSyncTimer()
        broadcastPlayback()
       
    }
    private func startSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
              guard let self,
                    self.isHost,
                    self.audio.isReadyToPlay,
                    self.audio.isPlaying else { return }

              self.broadcastPlayback()
          }
    }
    // MARK: - Play / Pause (HOST)
    func togglePlay() {
        guard isHost else { return }
        
        audio.isPlaying ? audio.pause() : audio.play()
        broadcastPlayback()
    }
    func seek(to value: Double) {
        guard isHost else { return }
        
        audio.seek(to: value)
        broadcastPlayback()
    }
    private func broadcastPlayback() {
        
        guard let track = selectedTrack else { return }
        
        let state = PlaybackState(
            roomId: roomId,
            trackUrl: track.url,
            position: audio.currentTime,
            isPlaying: audio.isPlaying,
            timestamp: Int(Date().timeIntervalSince1970)
        )
        
        rtc.sendPlaybackVer(roomId: roomId,
                            trackUrl: track.url,
                         position: audio.currentTime,
                         isPlaying: audio.isPlaying )
        rtc.sendData(state)
        print("📤 playback-state:", state)
    }
    
    func didReceivePlayback(_ state: PlaybackState) {
        guard !isHost else { return }

        print("📥 Playback recibido:", state)

        if selectedTrack?.url != state.trackUrl {
            let url = URL(string: state.trackUrl)!
            audio.loadRemote(url: url, title: "Remote")
        }
        
        let diff = abs(audio.currentTime - state.position)
        
        if diff > 0.7 {
            audio.seek(to: state.position)
        }
        
        state.isPlaying ? audio.play() : audio.pause()
        status = "Synced"
    }
    
    
    
    /// ⏸ Pause global (HOST)
    func pauseForEveryone() {
        guard isHost else { return }

        audio.pause()
        broadcastPlayback()
        print("⏸ Host pausó para todos")
    }

   
    
    // MARK: - MP3 Picker
    func pickMP3() {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.mp3],
            asCopy: true
        )
        picker.delegate = self
        picker.allowsMultipleSelection = false
        
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first?
            .rootViewController?
            .present(picker, animated: true)
    }
    
    func didReceiveRole(_ role: String) {
        isHost = (role == "host")
        print("👑 Rol asignado:", role)
    }

}

extension LibraryViewModel: UIDocumentPickerDelegate {

    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        guard let fileURL = urls.first else { return }

        // Acceso seguro (sandbox)
        let shouldStop = fileURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStop {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        Task {
            await uploadMP3(fileURL)
        }
    }

    func documentPickerWasCancelled(
        _ controller: UIDocumentPickerViewController
    ) {
        print("📂 Picker cancelado")
    }
   
    
    func upload(fileURL: URL) async throws -> AudioTrack {
        var request = URLRequest(url: URL(string: "https://t4videocall.t4ever.com/api/audio/upload")!)
        request.httpMethod = "POST"

        let (data, _) = try await URLSession.shared.upload(for: request, fromFile: fileURL)
        return try JSONDecoder().decode(AudioTrack.self, from: data)
    }
    func uploadMP3(_ fileURL: URL) async {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("/api/audio/upload")
        )
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()

        do {
            let fileData = try Data(contentsOf: fileURL)
            
            body.append("--\(boundary)\r\n")
            body.append(
                "Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n"
            )
            body.append("Content-Type: audio/mpeg\r\n\r\n")
            body.append(fileData)
            body.append("\r\n--\(boundary)--\r\n")
            
            let (_, response) = try await URLSession.shared.upload(
                for: request,
                from: body
            )
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                print("❌ Upload falló")
                return
            }
            
            print("✅ MP3 subido")
            await loadLibrary()
            
        } catch {
            print("❌ Error leyendo MP3 o subiendo:", error)
        }
    }
    func startBroadcastingPlayback() {
        stopBroadcastingPlayback()

        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self,
                  let track = self.selectedTrack else { return }

            self.rtc.sendPlaybackVer(
                roomId: self.roomId,
                trackUrl: track.url,
                position: self.audio.currentTime,
                isPlaying: self.audio.isPlaying
            )
        }
    }
    
    func stopBroadcastingPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
 
}
 
extension WebRTCManager {

    func sendPlayback(
        roomId: String,
        trackURL: URL,
        position: Double,
        isPlaying: Bool
    ) {
        let payload: [String: Any] = [
            "type": "playback-state",
            "room": roomId,
            "position": position,
            "isPlaying": isPlaying,
            "timestamp": Int(Date().timeIntervalSince1970)
        ]

        WebSocketSignaling.shared.send(payload)
    }
    func sendPlaybackVer(
        roomId: String,
        trackUrl: String,
        position: Double,
        isPlaying: Bool
    ) {
        let payload: [String: Any] = [
            "type": "playback-state",
            "room": roomId,
            "position": position,
            "trackUrl" : trackUrl,
            "isPlaying": isPlaying,
            "timestamp": Int(Date().timeIntervalSince1970)
        ]

        WebSocketSignaling.shared.send(payload)
    }
    
    
}
