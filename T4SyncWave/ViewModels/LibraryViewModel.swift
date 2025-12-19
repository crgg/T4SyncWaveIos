import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

/**
      
 
 */

@MainActor
final class LibraryViewModel: NSObject,  ObservableObject, WebRTCPlaybackDelegate,  WebRTCRoleDelegate {

    let libraryService = LibraryService.shared
   
    // MARK: - Timer (re-sync)
    private var syncTimer: Timer?
    let audio = AudioPlayerManager.shared
    let rtc = WebRTCManager.shared
    
    // MARK: - UI State
    @Published var tracks: [AudioTrack] = []
    @Published var selectedTrack: AudioTrack?
    @Published var isHost: Bool = true
    @Published var status: String = "Idle"
  
    @Published var isPlaying: Bool = false
    @Published var isUploading: Bool = false

    // MARK: - Room / Role
//    let roomId: String
//    let userName: String
    
      var joinSend: JoinSend?
      var groupModel: GroupDetail?
    
    
    
    private var playbackTimer: Timer?
    
    

    private let baseURL = URL(string: "https://t4videocall.t4ever.com")!
    
    // MARK: - Init
    init(groupModel: GroupDetail?) {
        guard let current_user = SessionStore.shared.loadUser() else {
            
            fatalError("No user")
        }
        if let groupModel  {
            self.groupModel = groupModel
            //            self.roomId = roomId
            //            self.userName = userName
            /**
             let type : String = "join"
             let room : String
             let userId : String
             let UserName : String
             let role : String
             */
          
            
            self.joinSend = JoinSend(type: "join", room: groupModel.id, userId: current_user.id, UserName: current_user.name, role: current_user.role ?? "member" )
            
            
            // Connect signaling
            /**
                                AQUI SE HACE LA CONNECTION A LA SOCKET LA VAMOS A DESCONECTAR
             **/
//            WebSocketSignaling.shared.connect(joinSend: joinSend)
//            rtc.playbackDelegate = self
//            rtc.roleDelegate = self
//           
            /******************************************************/
            
            // Load library
            // Load library
//            Task {
//                await loadLibrary()
//            }
            
        }
        
        //        else {
        //            self.roomId = "ramon1"
        //            self.userName = "ramon2"
        //            super.init()
        super.init( )
        Task {
            await self.loadLibraryList()
        }
        //        }
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
    
    func loadLibraryList() async {
        do {
            let response = try await libraryService.listTracks()
            tracks = response.audio
        } catch {
            print("error \(error.localizedDescription)")
        }
    }
    
    

    // MARK: - User Actions

    /// ▶️ Seleccionar y reproducir (HOST)
    func select(_ track: AudioTrack) {
        
        guard isHost else { return }
        
        // Si es el mismo track → toggle
        if selectedTrack?.id == track.id {
            togglePlay()
            return
        }
        
        print("🎧 Track seleccionado:", track.title)
        
        let url = URL(string: track.file_url)!
        audio.loadRemote(url: url, title: track.title)
        
        selectedTrack = track        // 👈 primero
        isPlaying = true             // 👈 UI inmediata
        
        audio.play()                 // 👈 async
        startSyncTimer()
        broadcastPlayback()
        
        
       
    }
    
    func stop() {
        audio.pause()
        isPlaying = false
        selectedTrack = nil
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

        if isPlaying {
            audio.pause()
            isPlaying = false
        } else {
            audio.play()
            isPlaying = true
        }

        broadcastPlayback()
    }

    func seek(to value: Double) {
        guard isHost else { return }
        
        audio.seek(to: value)
        broadcastPlayback()
    }
    private func broadcastPlayback() {
        
        guard let track = selectedTrack else { return }
        guard let groupModel = self.groupModel else { return }
        let state = PlaybackState(
            roomId: groupModel.id,
            trackUrl: track.file_url,
            position: audio.currentTime,
            isPlaying: audio.isPlaying,
            timestamp: Int(Date().timeIntervalSince1970)
        )
        
        rtc.sendPlaybackVer(roomId: groupModel.id,
                            trackUrl: track.file_url,
                         position: audio.currentTime,
                         isPlaying: audio.isPlaying )
        rtc.sendData(state)
        print("📤 playback-state:", state)
    }
    
    func didReceivePlayback(_ state: PlaybackState) {
        guard !isHost else { return }

        print("📥 Playback recibido:", state)

        if selectedTrack?.file_url != state.trackUrl {
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
        
        // Usar topViewController para presentar correctamente desde sheets
        UIApplication.shared.topViewController()?.present(picker, animated: true)
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
//            await uploadMP3(fileURL)
            await uploadMP3ToServer(fileURL)
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
            guard let groupModel = self.groupModel else { return }

            self.rtc.sendPlaybackVer(
                roomId: groupModel.id,
                trackUrl: track.file_url,
                position: self.audio.currentTime,
                isPlaying: self.audio.isPlaying
            )
        }
    }
    
    func stopBroadcastingPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    func syncTime() -> TimeInterval {
        print("Syncing time to:  \(audio.currentTime)")
        return audio.currentTime
    }
    func clearSelection() {
        self.selectedTrack = nil
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


extension LibraryViewModel {
    
    func uploadMP3ToServer(_ fileURL: URL) async {
        isUploading = true
        defer { isUploading = false }
        
        var request = URLRequest(
            url: baseURL.appendingPathComponent("/api/audio_test/upload")
        )
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        guard let token = KeychainManager.getAuthToken() else {
            print("no token 370 ")
            return
        }
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

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
            await loadLibraryList()
        } catch {
            print("❌ Error leyendo MP3 o subiendo:", error)
        }
    }
}
