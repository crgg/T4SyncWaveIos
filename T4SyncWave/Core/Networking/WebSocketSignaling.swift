//
//  WebSocketSignaling.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation
import Combine

struct JoinSend {
    let type : String
    let room : String
    let userId : String
    let UserName : String
    let role : String
    let trackUrl: String?
}

enum WebSocketConnectionState {
    case disconnected
    case connecting
    case connected
    case reconnecting
}

final class WebSocketSignaling: NSObject, ObservableObject, URLSessionWebSocketDelegate {

    static let shared = WebSocketSignaling()

    // 🔴 AQUÍ VA TU BACKEND URL
    private let url = URL(string: "wss://t4videocall.t4ever.com/sfu-video/ws")!

    private var socket: URLSessionWebSocketTask?
    private var session: URLSession!
    
    // Estado de conexión
    @Published private(set) var connectionState: WebSocketConnectionState = .disconnected
    
    // Para reconexión
    private var lastJoinSend: JoinSend?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var reconnectTimer: Timer?
    private var pingTimer: Timer?
    private var manualDisconnect = false  // Para evitar reconexión automática al desconectar manualmente

    override init() {
        super.init()
        // Crear session con delegate para detectar desconexiones
        session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }

    func connect(joinSend: JoinSend) {
        // Evitar múltiples conexiones simultáneas
        guard connectionState != .connecting && connectionState != .connected else {
            print("⚠️ Ya hay una conexión en progreso o activa, ignorando nueva solicitud")
            return
        }

        // Guardar para reconexión
        lastJoinSend = joinSend
        reconnectAttempts = 0

        performConnect(joinSend: joinSend)
    }
    
    private func performConnect(joinSend: JoinSend) {
        // Cancelar conexión anterior si existe
        disconnect()
        
        connectionState = .connecting
        print("🔌 WebSocket conectando...")
        
        socket = session.webSocketTask(with: url)
        socket?.resume()

        // Pequeño delay antes de enviar el mensaje de join para asegurar que la conexión esté establecida
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            var joinMessage: [String: Any] = [
                "type": joinSend.type,
                "room": joinSend.room,
                "userId": joinSend.userId,
                "userName": joinSend.UserName,
                "role": joinSend.role
            ]

            // Agregar trackUrl si existe
            if let trackUrl = joinSend.trackUrl {
                joinMessage["trackUrl"] = trackUrl
            }
            print("📤 ENVIANDO JOIN: \(joinMessage)")
            self.send(joinMessage)
        }

        listen()
        startPingTimer()

        connectionState = .connected
        manualDisconnect = false  // Reset flag cuando se conecta exitosamente
        print("✅ WebSocket conectado")
    }
    
    /// Reconectar usando la última configuración
    func reconnect(joinSend: JoinSend? = nil) {
        // Evitar reconexiones si ya hay una conexión en progreso
        guard connectionState != .connecting else {
            print("⚠️ Ya hay una conexión en progreso, esperando antes de reconectar")
            return
        }

        let sendData = joinSend ?? lastJoinSend

        guard let sendData else {
            print("⚠️ No hay datos de conexión para reconectar")
            return
        }

        // Actualizar lastJoinSend si se proporciona uno nuevo
        if joinSend != nil {
            lastJoinSend = joinSend
        }

        connectionState = .reconnecting
        print("🔄 Reconectando WebSocket (intento \(reconnectAttempts + 1)/\(maxReconnectAttempts))...")

        performConnect(joinSend: sendData)
    }
    
    /// Desconectar y limpiar
    func disconnect() {
        print("🔌 Desconexión manual iniciada - no reconectar automáticamente")
        manualDisconnect = true
        stopPingTimer()
        stopReconnectTimer()
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        connectionState = .disconnected
    }
    
    /// Verificar si está conectado
    var isConnected: Bool {
        connectionState == .connected
    }

    /// Último JoinSend para acceder desde otros managers
    var currentJoinSend: JoinSend? {
        lastJoinSend
    }

    func send(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let text = String(data: data, encoding: .utf8) else { return }

        socket?.send(.string(text)) { [weak self] error in
            if let error = error {
                print("❌ WS send error:", error)
                print("🐛 DEBUG: Error de envío, llamando handleConnectionError")
                 
                if self?.manualDisconnect == false {
                    self?.handleConnectionError()
                }
            }
        }
    }

    private func listen() {
        socket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handle(message)
                self?.listen()
            case .failure(let error):
                print("❌ WS receive error:", error)
                print("🐛 DEBUG: Error de recepción en listen(), llamando handleConnectionError")
                if self?.manualDisconnect == false {
                    self?.handleConnectionError()
                }
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        guard case .string(let text) = message else { return }

           print("📩 WS recibido:", text)

           guard
               let data = text.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { 
            print("❌ Error parsing JSON from WS message")
            return 
        }
        
        // Reset reconnect attempts on successful message
        reconnectAttempts = 0
        
        // Log specific message types
        if let type = json["type"] as? String {
            print("📩 WS tipo: \(type)")
            if type == "playback-state" {
                let isPlaying = json["isPlaying"] as? Bool ?? false
                let position = json["position"] as? Double ?? 0
                print("🎵 PLAYBACK-STATE recibido: isPlaying=\(isPlaying), position=\(position)")
            }
            // Log presence events
            if type == "user-joined" || type == "joined" || type == "user-left" || type == "left" {
                print("👥 WS PRESENCE EVENT: \(type) - \(json)")
            }
        }
        
           WebRTCManager.shared.handleSignaling(json)
    }
    
    // MARK: - Connection Error Handling
    
    private func handleConnectionError() {
        guard connectionState != .reconnecting else { return }

        // No reconectar si fue una desconexión manual
        if manualDisconnect {
            print("🔌 Desconexión manual detectada - no reconectar")
            manualDisconnect = false  // Reset para futuras conexiones
            return
        }

        print("🐛 DEBUG: handleConnectionError() llamado desde: \(Thread.callStackSymbols[1])")
        print("🐛 DEBUG: Estado actual antes del error: \(connectionState)")

        connectionState = .disconnected
        scheduleReconnect()
    }
    
    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("❌ Máximo de intentos de reconexión alcanzado")
            return
        }

        stopReconnectTimer()

        // Backoff exponencial: 1s, 2s, 4s, 8s, 16s
        let delay = pow(2.0, Double(reconnectAttempts))
        reconnectAttempts += 1

        print("⏰ Reconexión programada en \(delay) segundos...")
        print("🐛 DEBUG: scheduleReconnect() llamado desde: \(Thread.callStackSymbols[1])")

        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.reconnect()
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    // MARK: - Ping/Pong para mantener conexión viva
    
    private func startPingTimer() {
        stopPingTimer()

        // Enviar pings cada 45 segundos (menos frecuente que server-ping cada ~25-30s)
        // para no interferir con el sistema server-ping/server-pong
        pingTimer = Timer.scheduledTimer(withTimeInterval: 45, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() {
        socket?.sendPing { [weak self] error in
            if let error = error {
                print("❌ Ping failed:", error)
                self?.handleConnectionError()
            } else {
                print("🏓 Ping OK")
            }
        }
    }
    
    // MARK: - URLSessionWebSocketDelegate
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket didOpen")
        DispatchQueue.main.async {
            self.connectionState = .connected
            self.reconnectAttempts = 0

            // Si estamos reconectando y somos listener, solicitar estado de playback inmediatamente
            if let joinSend = self.lastJoinSend, joinSend.role == "member" {
                print("🎧 Reconexión exitosa como listener, solicitando estado de playback")
                let requestMessage: [String: Any] = [
                    "type": "request-playback-state",
                    "roomId": joinSend.room
                ]
                // Pequeño delay para asegurar que la conexión esté establecida
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.send(requestMessage)
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("🔴 WebSocket didClose: \(closeCode)")

        // No reconectar si fue una desconexión manual
        if manualDisconnect {
            print("🔌 Cierre por desconexión manual - no reconectar")
//            manualDisconnect = false  // Reset para futuras conexiones
            DispatchQueue.main.async {
                self.connectionState = .disconnected
            }
            return
        }

        // Log detallado del código de cierre
        switch closeCode {
        case .normalClosure:
            print("📋 Cierre normal (1000)")
        case .goingAway:
            print("📋 Servidor cerró conexión intencionalmente (1001) - reconectando...")
        case .protocolError:
            print("📋 Error de protocolo (1002)")
        case .unsupportedData:
            print("📋 Datos no soportados (1003)")
        case .noStatusReceived:
            print("📋 No se recibió status (1005)")
        case .abnormalClosure:
            print("📋 Cierre anormal (1006)")
        case .invalidFramePayloadData:
            print("📋 Payload inválido (1007)")
        case .policyViolation:
            print("📋 Violación de política (1008)")
        case .messageTooBig:
            print("📋 Mensaje demasiado grande (1009)")
        case .mandatoryExtensionMissing:
            print("📋 Extensión obligatoria faltante (1010)")
        case .internalServerError:
            print("📋 Error interno del servidor (1011)")
        case .tlsHandshakeFailure:
            print("📋 Fallo en handshake TLS (1015)")
        default:
            print("📋 Código de cierre desconocido: \(closeCode.rawValue)")
        }

        if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
            print("📋 Razón del cierre: \(reasonString)")
        }

        DispatchQueue.main.async {
            self.connectionState = .disconnected
            self.scheduleReconnect()
        }
    }
}
