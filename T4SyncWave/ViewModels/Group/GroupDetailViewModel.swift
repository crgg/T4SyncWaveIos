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
final class GroupDetailViewModel: ObservableObject, WebRTCPlaybackDelegate, WebRTCRoleDelegate, WebRTCMemberPresenceDelegate {

    
    @Published var group: GroupDetail?
    @Published var isLoading = true
    @Published var error: String?
    @Published var isPlaying: Bool = false
    @Published var selectedTrack: GroupTrack?
    
    // Track online members by their userId
    @Published var onlineMembers: Set<String> = []
    
    // Toast message when someone joins
    @Published var toastMessage: String?
    
    // Mute state for listeners
    @Published var isMuted: Bool = false

    // Repeat mode
    var isRepeatEnabled: Bool {
        get { audio.isRepeatEnabled }
        set { audio.isRepeatEnabled = newValue }
    }

    // Current user ID
    let currentUserId: String
        
    let audio = AudioPlayerManager.shared
    let rtc = WebRTCManager.shared
    private var syncTimer: Timer?
    private var uiTimer: Timer?     // UI
    private var playbackStateRequestTimer: Timer?  // Timer para reintentar solicitud de estado
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
        self.currentUserId = SessionStore.shared.loadUser()?.id ?? ""
        rtc.playbackDelegate = self
        rtc.roleDelegate = self
        rtc.presenceDelegate = self
        
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

        // Observer para cuando la música termina localmente
        NotificationCenter.default.publisher(for: .audioDidFinishPlaying)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleAudioDidFinish()
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

    private func handleAudioDidFinish() {
        print("🏁 Música terminó localmente")
        // Solo marcar como terminada si estamos reproduciendo
        // No pausar automáticamente ya que el DJ podría reiniciar
        if isPlaying && !isRepeatEnabled {
            print("🎵 Música terminó, esperando comando del DJ para continuar")
        }
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

    func didReceivePlaybackStateRequest() {
        // Solo responder si somos DJ y hay música reproduciéndose
        guard !isListener, let track = selectedTrack, audio.isReadyToPlay else {
            print("⏭️ Ignorando request-playback-state (no somos DJ o no hay track)")
            return
        }

        print("📤 Enviando estado de playback solicitado")
        broadcastPlayback()
    }

    func didReceivePlayback(_ state: PlaybackState) {
        
        print("📥 Playback recibido: isPlaying=\(state.isPlaying), position=\(state.position)")
        guard isListener else { 
            print("⏭️ Ignorando playback (soy DJ)")
            return 
        }

        guard let g = self.group else { return }
 
        // Cargar track si cambió
        if selectedTrack?.fileURL.absoluteString != state.trackUrl {
            if let trackUrl = state.trackUrl, let url = URL(string: trackUrl) {
                print("🎵 Cargando nuevo track: \(trackUrl)")
                audio.loadRemote(url: url, title: "Remote")
            } else {
                print("🎵 No hay track para cargar (trackUrl es nil)")
                // Si no hay track, detener reproducción
                audio.pause()
                selectedTrack = nil
            }

            // Actualizar selectedTrack y duration desde el grupo
            if let track = g.currentTrack {
                selectedTrack = track
                duration = Double(track.durationMs) / 1000
            }
        }

        // Calcular posición ajustada considerando el tiempo de viaje del mensaje
        let currentTime = Date().timeIntervalSince1970
        let messageAge = currentTime - Double(state.timestamp)
        let adjustedRemotePosition = state.position + messageAge // Ajustar por el tiempo que tardó el mensaje

        print("📊 Debug: messageAge=\(String(format: "%.2f", messageAge))s, adjustedPosition=\(String(format: "%.2f", adjustedRemotePosition))")

        // Sincronizar posición con lógica mejorada
        let diff = abs(audio.currentTime - adjustedRemotePosition)
        let duration = audio.duration
        let isNearEnd = duration > 0 && adjustedRemotePosition > (duration - 2.0) // Dentro de los últimos 2 segundos
        let isLocalNearEnd = duration > 0 && audio.currentTime > (duration - 2.0) // Local también cerca del final

        // Detectar reinicio desde el principio
        let isRestartFromBeginning = audio.currentTime > 5.0 && adjustedRemotePosition < 2.0 && state.isPlaying
        let isJumpToBeginning = adjustedRemotePosition < 1.0 && state.isPlaying

        if isRestartFromBeginning {
            print("🔄 DJ reinició la música desde el principio")
            // Forzar sincronización inmediata cuando el DJ reinicia
        }
        

        // No sincronizar si ambos están cerca del final (música terminando)
        if isNearEnd && isLocalNearEnd && !isRestartFromBeginning {
            print("🎵 Ambos cerca del final (duración=\(String(format: "%.1f", duration))), no sincronizar")
            return
        }

        // Si el DJ pausó cerca del final, no sincronizar para evitar saltos
        if isNearEnd && !state.isPlaying && !isRestartFromBeginning {
            print("🎵 DJ pausó cerca del final, no sincronizar")
            return
        }

        // Sincronizar si hay diferencia significativa o es un reinicio
        // Umbral más agresivo para mejor sincronización
        let syncThreshold: Double
        if isRestartFromBeginning || isJumpToBeginning {
            syncThreshold = 0.3 // Reinicios: sincronizar inmediatamente
            print("🔄 Reinicio detectado, sincronizando inmediatamente")
        } else if diff > 30.0 {
            syncThreshold = 3.0 // Grandes diferencias: ser más permisivo
        } else if diff > 10.0 {
            syncThreshold = 2.0
        } else if diff > 3.0 {
            syncThreshold = 1.0
        } else {
            syncThreshold = 0.5 // Reducido de 0.8 a 0.5 para mejor sincronización
        }

        if diff > syncThreshold || isRestartFromBeginning || isJumpToBeginning {
            print("⏱️ Sincronizando posición: local=\(String(format: "%.2f", audio.currentTime)), remoto=\(String(format: "%.2f", adjustedRemotePosition)), original=\(String(format: "%.2f", state.position)), diff=\(String(format: "%.2f", diff)), threshold=\(syncThreshold)")

            // Validar que la posición remota sea razonable
            let maxAllowedPosition = duration > 0 ? duration + 10.0 : 3600.0  // Si duration=0, permitir hasta 1 hora
            if adjustedRemotePosition >= 0 && adjustedRemotePosition <= maxAllowedPosition {
                audio.seek(to: adjustedRemotePosition)
                localCurrentTime = adjustedRemotePosition
                print("✅ Sincronización completada")
            } else {
                print("⚠️ Posición remota inválida: \(adjustedRemotePosition), duración=\(String(format: "%.1f", duration))")
            }
        } else {
            print("⏸️ No sincronizando: diff=\(String(format: "%.2f", diff)) <= threshold=\(syncThreshold)")
        }
        
        // Actualizar estado de reproducción
        let wasPlaying = isPlaying
        if state.isPlaying {
            if !wasPlaying {
                print("▶️ Iniciando reproducción (comando del DJ)")
            }
            audio.play()
            isPlaying = true
            group?.isPlaying = true
            startUITimer()
        } else {
            if wasPlaying {
                print("⏸️ Pausando reproducción (comando del DJ)")
            }
            audio.pause()
            isPlaying = false
            group?.isPlaying = false
            stopUITimer()
        }
    }
    
    func didReceiveRole(_ role: String) {
        print("👑 Rol asignado:", role)
        isListener = (role == "member")

        // When we receive our role, we are connected, mark ourselves as online
        markCurrentUserOnline()

        // Si somos listener, obtener estado inicial y programar solicitud de estado de playback
        if isListener {
            Task {
                await fetchInitialRoomState()
            }
            schedulePlaybackStateRequest()
        }
    }
    
    /// Mark the current user as online
    private func markCurrentUserOnline() {
        // Add current user ID to online members
        if !currentUserId.isEmpty {
            onlineMembers.insert(currentUserId)
            print("✅ Usuario actual marcado como online: \(currentUserId)")
        }
        
        // Also try to find by name in member list (match with current user's name)
        if let currentUserName = SessionStore.shared.loadUser()?.name,
           let member = group?.members.first(where: { $0.name.lowercased() == currentUserName.lowercased() }) {
            onlineMembers.insert(member.id)
            print("✅ Miembro actual marcado como online por nombre: \(member.id)")
        }
    }
    
    // MARK: - WebRTCMemberPresenceDelegate
    
    func didMemberJoin(userId: String, userName: String, room: String) {
        guard room == groupId else { return }
        guard userId != currentUserId else { 
            // Current user joined, mark as online
            markCurrentUserOnline()
            return 
        }
        
        print("✅ Miembro conectado: \(userName) (\(userId))")
        onlineMembers.insert(userId)
        
        // Show toast
        showToast("\(userName) joined")
    }
    
    func didMemberLeave(userId: String, userName: String, room: String) {
        guard room == groupId else { return }
        guard userId != currentUserId else { return }
        
        print("❌ Miembro desconectado: \(userName) (\(userId))")
        onlineMembers.remove(userId)
        
        // Show toast
        showToast("\(userName) left")
    }
    
    func didReceiveRoomUsers(_ users: [RoomUser], room: String) {
        guard room == groupId else { return }
        
        print("👥 Usuarios en sala (\(users.count)): \(users.map { "\($0.userName) (\($0.role))" })")
        print("👥 Miembros del grupo: \(group?.members.map { "\($0.name) (id:\($0.id))" } ?? [])")
        
        // Update online members based on room users
        for user in users {
            // Try to match by userName (case-insensitive)
            if let member = group?.members.first(where: { 
                $0.name.lowercased() == user.userName.lowercased() 
            }) {
                onlineMembers.insert(member.id)
                print("✅ Match encontrado: \(user.userName) -> member.id: \(member.id)")
            } else {
                print("⚠️ No se encontró match para: \(user.userName)")
            }
        }
        
        // Always mark current user as online if we're in this room
        markCurrentUserOnline()
        
        print("👥 onlineMembers actualizado: \(onlineMembers)")
    }
    
    /// Show a toast message that auto-dismisses
    private func showToast(_ message: String) {
        toastMessage = message
        
        // Auto dismiss after 3 seconds
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }
    
    /// Check if a member is online by their member ID or user ID
    func isMemberOnline(_ memberId: String) -> Bool {
        onlineMembers.contains(memberId)
    }
    
    /// Get DJ member from group
    var djMember: GroupMember? {
        group?.members.first { $0.role == .dj }
    }
    
    /// Get listeners (excluding DJ and current user)
    var listenerMembers: [GroupMember] {
        guard let members = group?.members else { return [] }
        return members.filter { member in
            member.role != .dj && member.id != currentUserId
        }
    }
    
    /// Toggle mute for listeners (local only, doesn't affect DJ)
    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            audio.setVolume(0)
            print("🔇 Audio silenciado")
        } else {
            audio.setVolume(1)
            print("🔊 Audio activado")
        }
    }

    func toggleRepeat() {
        audio.toggleRepeat()
        print("🔁 Repeat \(audio.isRepeatEnabled ? "activado" : "desactivado")")
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
            let hasFinished = duration > 0 && (localCurrentTime >= duration - 1.0 || audio.currentTime >= duration - 1.0)
            if hasFinished {
                print("🔄 Música terminada, reiniciando al principio (local=\(String(format: "%.2f", localCurrentTime)), duration=\(String(format: "%.2f", duration)))")
                localCurrentTime = 0
                group?.currentTimeMs = 0
                audio.seek(to: 0)
                // Pequeña pausa para asegurar que el seek se complete
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 segundos
                    self.startPlaying(track)
                }
                return
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

    // MARK: - Playback State Request for Listeners

    private func schedulePlaybackStateRequest() {
        stopPlaybackStateRequestTimer()

        // Solicitar estado de playback cada 3 segundos durante 30 segundos
        // por si la solicitud inicial no llega o se pierde
        playbackStateRequestTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isListener else { return }
                self.requestPlaybackState()
            }
        }

        // Detener después de 30 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [weak self] in
            self?.stopPlaybackStateRequestTimer()
        }
    }

    private func requestPlaybackState() {
        guard let room = WebRTCManager.getCurrentRoom() else {
            print("⚠️ No room available for playback state request")
            return
        }

        let requestMessage: [String: Any] = [
            "type": "request-playback-state",
            "room": room
        ]

        // Usar WebSocketSignaling para enviar la solicitud directamente
        WebRTCManager.sendSignalingMessage(requestMessage)
        print("🎧 Solicitando estado de playback al DJ...")
    }

    private func stopPlaybackStateRequestTimer() {
        playbackStateRequestTimer?.invalidate()
        playbackStateRequestTimer = nil
    }

    // MARK: - WebRTCPlaybackDelegate

    func didReceivePlaybackStateRequest() {
        // Responder con el estado actual de reproducción si somos DJ
        guard !isListener else {
            print("🎧 Listener recibió request-playback-state, ignorando (solo DJ responde)")
            return
        }

        print("🎤 DJ respondiendo a solicitud de estado de playback")
        broadcastPlayback()
    }

    // MARK: - Room State Synchronization

    func fetchInitialRoomState() async {
        guard isListener, let groupId = group?.id else {
            print("⚠️ fetchInitialRoomState: Solo listeners pueden obtener estado inicial")
            return
        }

        do {
            let roomState = try await GroupService.shared.getRoomState(roomId: groupId)
            print("📡 Estado inicial de sala obtenido: \(roomState.members.count) miembros")

            // Actualizar miembros online basados en el estado de la sala
            let onlineUserIds = Set(roomState.members.map { $0.odooUserId })
            onlineMembers = onlineUserIds

            // Si hay estado de reproducción, sincronizar
            if let playback = roomState.playbackState.trackUrl {
                // Hay música reproduciéndose, el listener se sincronizará vía WebSocket
                print("🎵 Sala tiene música reproduciéndose, esperando sincronización WebSocket")
            } else {
                print("🎵 Sala sin música activa")
            }

        } catch {
            print("❌ Error obteniendo estado inicial de sala: \(error)")
        }
    }

    //{"type":"playback-state","trackUrl":"https://go2storage.s3.us-east-2.amazonaws.com/audio/df6bd099-f188-4cae-8265-b88ab99497f8.mp3","position":0,"isPlaying":true,"timestamp":1766118083}
}

