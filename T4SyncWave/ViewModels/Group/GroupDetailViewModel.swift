//
//  GroupDetailViewModel.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/18/25.
//

import Foundation
import Combine
import UIKit

@MainActor
final class GroupDetailViewModel: ObservableObject, WebRTCPlaybackDelegate,  WebRTCRoleDelegate  {

    
    @Published var group: GroupDetail?
    @Published var isLoading = true
    @Published var error: String?
    @Published var isPlaying: Bool = false
    @Published var selectedTrack: GroupTrack?
        
    let audio = AudioPlayerManager.shared
    let rtc = WebRTCManager.shared
    private var syncTimer: Timer?
    
    
    private var uiTimer: Timer?     // UI
    var isListener : Bool = false
    @Published var localCurrentTime: Double = 0
    @Published var duration: Double = 0
    
    // Para reconexión
    private var lastJoinSend: JoinSend?
    private var cancellables = Set<AnyCancellable>()
    
    let groupId: String
    //  initialize the view model with the group id and the listener role
    init(groupId: String, isListener: Bool = false) {
        self.groupId = groupId
        self.isListener = isListener
        rtc.playbackDelegate = self
        rtc.roleDelegate = self
        
        // Observar cuando la app vuelve a primer plano
        setupAppLifecycleObservers()
    }
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleAppWillEnterForeground()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleAppDidEnterBackground()
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleAppWillEnterForeground() {
        print("📱 App volvió a primer plano - reconectando...")
        reconnectIfNeeded()
    }
    
    private func handleAppDidEnterBackground() {
        print("📱 App entró en background")
        // Opcional: pausar timers para ahorrar batería
    }
    
    func reconnectIfNeeded() {
        guard let joinSend = lastJoinSend else {
            print("⚠️ No hay joinSend guardado para reconectar")
            return
        }
        
        // Reconectar WebSocket
        WebSocketSignaling.shared.reconnect(joinSend: joinSend)
        
        // Si estaba reproduciendo, reiniciar el timer
        if isPlaying {
            startUITimer()
            if !isListener {
                startSyncTimer()
            }
        }
    }
    // Charge all groups
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await GroupService.shared.getGroup(id: groupId)
            group = result.group
            if let gr = group {
                initalConnction(gr)
            }
            
        } catch {
            self.error = error.localizedDescription
        }
    }
    var nowPlayingState: NowPlayingUIState? {
        guard let g = group,
              let track = g.currentTrack else { return nil }
        
        return NowPlayingUIState(
            trackTitle: track.title,
            artist: track.artist,
            duration: Double(track.durationMs) / 1000,
            currentTime: Double(g.currentTimeMs) / 1000,
            isPlaying: g.isPlaying
        )
    }
    
    func syncFromGroupState() {
        guard let g = group else { return }

        localCurrentTime = Double(g.currentTimeMs) / 1000
        duration = Double(g.currentTrack?.durationMs ?? 0) / 1000
    }
    
    func addMember(groupId: String, email : String) async -> Bool {
        do {
            let requestd = AddMemberRequest(groupId: groupId, email: email)
            
           let response = try await GroupService.shared.addMember(request: requestd)
            if response.status {
                if let m = response.member {
                    let url = URL(string: m.user.avatarURL ?? "") ?? nil
                    
                    let nm = GroupMember(id: m.id, name: m.user.name, email: m.user.email, role: .member, avatarURL: url)
                     group?.members.insert(nm, at: 0)
                }
                return true
            } else {
                self.error = response.msg ?? "Error unknown"
                return false
            }
           
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
    
    // add music
    private let baseURL = URL(string: "https://t4videocall.t4ever.com")!
    func uploadMP3ToServer(_ fileURL: URL) async {
        
        var request = URLRequest(
            url: baseURL.appendingPathComponent("/api/audio_test/upload")
        )
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        guard let token  = KeychainManager.getAuthToken() else {
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
//            await loadLibraryList()
        } catch {
            print("❌ Error leyendo MP3 o subiendo:", error)
        }
    }
//    private func mapNowPlaying() {
//        guard let track = group.currentTrack else {
//            nowPlayingState = nil
//            return
//        }
//
//        nowPlayingState = NowPlayingUIState(
//            trackTitle: track.title,
//            artist: track.artist,
//            duration: Double(track.durationMs) / 1000,
//            currentTime: Double(group.currentTimeMs) / 1000,
//            isPlaying: group.isPlaying
//        )
//    }
    
//    var membersCount: Int {
//        group.members.count
//    }
//
//    var dj: GroupMember? {
//        group.members.first { $0.role == .dj }
//    }
//
//    var listeners: [GroupMember] {
//        group.members.filter { $0.role == .member }
//    }
    
    func didReceivePlayback(_ state: PlaybackState) {
        
        print("📥 Playback recibido:", state)
        guard isListener else { return }

        guard let g = self.group else { return }
 
        // Cargar track si cambió
        if selectedTrack?.fileURL.absoluteString != state.trackUrl {
            let url = URL(string: state.trackUrl)!
            audio.loadRemote(url: url, title: "Remote")
            
            // Actualizar selectedTrack y duration desde el grupo
            if let track = g.currentTrack {
                selectedTrack = track
                duration = Double(track.durationMs) / 1000
            }
        }
        
        // Sincronizar posición si hay diferencia significativa
        let diff = abs(audio.currentTime - state.position)
        if diff > 0.7 {
            audio.seek(to: state.position)
            localCurrentTime = state.position
        }
        
        // Actualizar estado de reproducción
        if state.isPlaying {
            audio.play()
            isPlaying = true
            group?.isPlaying = true
            startUITimer()  // 👈 Iniciar timer para actualizar segundos
        } else {
            audio.pause()
            isPlaying = false
            group?.isPlaying = false
            stopUITimer()
        }
    }
    
    func didReceiveRole(_ role: String) {
        print("👑 Rol asignado:", role)
    }
    func seek(to seconds: Double) {

        audio.seek(to: seconds)

        group?.currentTimeMs = Int(seconds * 1000)

        // Solo el controller envía
        if !isListener {
            broadcastPlayback()
        }
    }
    
    func skipBackward() {
        let newTime = max(0, localCurrentTime - 15)
        seek(to: newTime)
        localCurrentTime = newTime
    }
    
    func skipForward() {
        let newTime = min(duration, localCurrentTime + 15)
        seek(to: newTime)
        localCurrentTime = newTime
    }
    
    deinit {
        // Limpiar timers al destruir el ViewModel
        syncTimer?.invalidate()
        uiTimer?.invalidate()
    }
}

extension GroupDetailViewModel {
    func initalConnction(_ groupModel : GroupDetail) {
        guard let current_user = SessionStore.shared.loadUser() else {
            
            fatalError("No user")
        }
        
        let joinSend = JoinSend(type: "join", room: groupModel.id, userId: current_user.id, UserName: current_user.name, role: isListener ? "member" : "dj" )
        
        // Guardar para reconexión
        self.lastJoinSend = joinSend
        
        WebSocketSignaling.shared.connect(joinSend: joinSend)
        if isListener {
            selectedTrack = groupModel.currentTrack
            if let selectedTrack = selectedTrack {
                audio.loadRemote(url: selectedTrack.fileURL, title: "Remote")
                duration = Double(selectedTrack.durationMs) / 1000
            }
        }
        
    }
    func togglePlayPause() {
        
        guard let track = group?.currentTrack else { return }
        
        if isPlaying {
            pause(track)
        } else {
            // Si la música terminó, reiniciar al principio
            if duration > 0 && localCurrentTime >= duration - 0.5 {
                print("🔄 Música terminada, reiniciando al principio")
                localCurrentTime = 0
                group?.currentTimeMs = 0
                audio.seek(to: 0)
            }
            startPlaying(track)
        }
    }
    func pause(_ track: GroupTrack) {
        
        audio.pause()
        guard group != nil else { return }
        
        self.group?.isPlaying = false
        self.isPlaying = false
        group?.currentTimeMs = Int(audio.currentTime * 1000)
        isPlaying = false
        
        stopUITimer()
        stopSyncTimer()
        broadcastPlayback()
    }
    
    
    func startPlaying(_ track: GroupTrack)  {
        
        audio.loadRemote(url:  track.fileURL, title: track.title)
        
        selectedTrack = track        // 👈 primero
        isPlaying = true             // 👈 UI inmediata
        group?.isPlaying = true      // 👈 actualizar estado del grupo (para nowPlayingState)
        duration = Double(track.durationMs) / 1000  // 👈 actualizar duración
        
        audio.play()                 // 👈 async
        startSyncTimer()
        broadcastPlayback()
        startUITimer()
        
    }
    
    private func broadcastPlayback() {
        
        guard let track = selectedTrack else { return }
        guard let groupModel = self.group else { return }
        let state = PlaybackState(
            roomId: groupModel.id,
            trackUrl: track.fileURL.absoluteString,
            position: audio.currentTime,
            isPlaying: audio.isPlaying,
            timestamp: Int(Date().timeIntervalSince1970)
        )
        
        // Enviar via WebSocket
        let payload: [String: Any] = [
            "type": "playback-state",
            "room": groupModel.id,
            "position": audio.currentTime,
            "trackUrl": track.fileURL.absoluteString,
            "isPlaying": audio.isPlaying,
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        WebSocketSignaling.shared.send(payload)
        
        // También enviar via DataChannel si está disponible
        rtc.sendData(state)
        print("📤 playback-state:", state)
    }
    
    func stop() {
        audio.pause()
        isPlaying = false
        localCurrentTime = 0
        stopUITimer()
        stopSyncTimer()
        //        selectedTrack = nil
        broadcastPlayback()
    }
    private func startSyncTimer() {
        stopSyncTimer()
        
        // Crear timer y añadirlo al RunLoop principal explícitamente
        let timer = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self,
                      self.audio.isReadyToPlay,
                      self.audio.isPlaying else { return }
                
                self.broadcastPlayback()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        syncTimer = timer
    }
    
    private func stopSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    private func startUITimer() {
        stopUITimer()
        
        // Crear timer y añadirlo al RunLoop principal explícitamente
        // Usar .common para que funcione incluso durante scroll
        let timer = Timer(timeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self,
                      self.audio.isReadyToPlay,
                      self.audio.isPlaying else { return }
                
                self.localCurrentTime = self.audio.currentTime
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        uiTimer = timer
    }
    
    private func stopUITimer() {
        uiTimer?.invalidate()
        uiTimer = nil
    }
    //{"type":"playback-state","trackUrl":"https://go2storage.s3.us-east-2.amazonaws.com/audio/df6bd099-f188-4cae-8265-b88ab99497f8.mp3","position":0,"isPlaying":true,"timestamp":1766118083}
}

