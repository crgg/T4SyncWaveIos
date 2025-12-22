//
//  WebRTCManager.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation
import WebRTC
import Combine
import SwiftUI
    
protocol WebRTCPlaybackDelegate: AnyObject {
    func didReceivePlayback(_ state: PlaybackState)
}
protocol WebRTCRoleDelegate: AnyObject {
    func didReceiveRole(_ role: String)
}
protocol WebRTCMemberPresenceDelegate: AnyObject {
    func didMemberJoin(userId: String, userName: String, room: String)
    func didMemberLeave(userId: String, userName: String, room: String)
    func didReceiveRoomUsers(_ users: [RoomUser], room: String)
}

// User in room from "room-users" message
struct RoomUser: Codable {
    let peerId: String
    let userName: String
    let role: String
    let isHost: Bool
    let joinedAt: String
}
final class WebRTCManager: NSObject, ObservableObject {
    weak var roleDelegate: WebRTCRoleDelegate?
    weak var presenceDelegate: WebRTCMemberPresenceDelegate?

    static let shared = WebRTCManager()
    weak var playbackDelegate: WebRTCPlaybackDelegate?

    // Para debugging de heartbeat
    private var lastServerPingTime: Date?

    /// Verifica si el heartbeat está funcionando (último ping < 40 segundos)
    var isHeartbeatActive: Bool {
        guard let lastPing = lastServerPingTime else { return false }
        return Date().timeIntervalSince(lastPing) < 40.0
    }
        private var peerConnection: RTCPeerConnection?
        private var dataChannel: RTCDataChannel?
        private var factory: RTCPeerConnectionFactory!

        override init() {
            super.init()
            RTCInitializeSSL()
            factory = RTCPeerConnectionFactory()
        }
    

    
    func setRemoteAnswer(_ sdp: RTCSessionDescription) {
        Task {
            do {
                try await   peerConnection?.setRemoteDescription(sdp)
            } catch {
                print("Error setting local description:", error)
            }
        }
     
    }
    
 
    
    func addIceCandidate(_ candidate: RTCIceCandidate) {
        Task {
            do {
                try await   peerConnection?.add(candidate)
            } catch {
                print("Error setting local description:", error)
            }
        }
     
    }
    
    func sendData<T: Codable>(_ object: T) {

        guard let channel = dataChannel,
              channel.readyState == .open else { return }

        let data = try? JSONEncoder().encode(object)
        let buffer = RTCDataBuffer(data: data!, isBinary: false)

        channel.sendData(buffer)
    }
    
    func connect() {
        createPeerConnection()
        createDataChannel()

        createOffer { sdp in
            // enviar sdp.sdp al backend
        }
    }
    func handleSignaling(_ msg: [String: Any]) {

        guard let type = msg["type"] as? String else { return }

        switch type {
        case "offer":
            let sdp = RTCSessionDescription(
                type: .offer,
                sdp: msg["sdp"] as! String
            )
            setRemoteOffer(sdp)

        case "answer":
            let sdp = RTCSessionDescription(
                type: .answer,
                sdp: msg["sdp"] as! String
            )
            setRemoteAnswer(sdp)

        case "ice-candidate":
            let candidate = RTCIceCandidate(
                sdp: msg["candidate"] as! String,
                sdpMLineIndex: msg["sdpMLineIndex"] as! Int32,
                sdpMid: msg["sdpMid"] as? String
            )
            addIceCandidate(candidate)

        case "playback-state":
            do {
                let data = try JSONSerialization.data(withJSONObject: msg)
                let playback = try JSONDecoder().decode(PlaybackMessage.self, from: data)

                print("🎵 PlaybackMessage: isPlaying=\(playback.isPlaying), position=\(playback.position ?? 0), room=\(playback.room ?? "nil")")

                // Use room from message or fallback to current room from WebRTC
                let roomId = playback.room ?? (lastJoinSend?.room ?? "")

                let state = PlaybackState(
                    roomId: roomId,
                    trackUrl: playback.trackUrl,
                    position: playback.position ?? 0,
                    isPlaying: playback.isPlaying,
                    timestamp: playback.timestamp
                )

                playbackDelegate?.didReceivePlayback(state)

            } catch {
                print("❌ Error decodificando PlaybackMessage:", error)
                // Log the raw message for debugging
                print("📩 Raw playback-state message:", msg)
            }

        case "role":
            if let role = msg["role"] as? String {
                    DispatchQueue.main.async {
                        self.roleDelegate?.didReceiveRole(role)
                    }
                }

        case "server-ping":
            // ⚡ IMPORTANTE: Responder inmediatamente al server-ping para mantener conexión viva
            // El servidor desconecta si no responde en < 35 segundos
            lastServerPingTime = Date()
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            print("🏓 Server-ping recibido (timestamp: \(timestamp)), respondiendo server-pong")
            let pongMessage: [String: Any] = [
                "type": "server-pong",
                "timestamp": timestamp
            ]
            WebSocketSignaling.shared.send(pongMessage)

        case "welcome":
            // Server welcome message with peerId and role
            let role = msg["role"] as? String ?? ""
            let isHost = msg["isHost"] as? Bool ?? false
            print("👋 Welcome: role=\(role), isHost=\(isHost)")
            DispatchQueue.main.async {
                self.roleDelegate?.didReceiveRole(role)
            }
            
        case "room-users":
            // List of all users in the room
            if let room = msg["room"] as? String,
               let usersArray = msg["users"] as? [[String: Any]] {
                do {
                    let data = try JSONSerialization.data(withJSONObject: usersArray)
                    let users = try JSONDecoder().decode([RoomUser].self, from: data)
                    print("👥 Room users: \(users.count) usuarios en sala")
                    DispatchQueue.main.async {
                        self.presenceDelegate?.didReceiveRoomUsers(users, room: room)
                    }
                } catch {
                    print("❌ Error parsing room-users:", error)
                }
            }
            
        case "joined":
            // Un usuario se unió a la sala
            let userId = msg["userId"] as? String ?? ""
            let userName = msg["userName"] as? String ?? ""
            let room = msg["room"] as? String ?? ""
            print("👤 Usuario conectado: \(userName) en sala \(room)")
            DispatchQueue.main.async {
                self.presenceDelegate?.didMemberJoin(userId: userId, userName: userName, room: room)
            }
            
        case "left":
            // Un usuario dejó la sala
            let userId = msg["userId"] as? String ?? ""
            let userName = msg["userName"] as? String ?? ""
            let room = msg["room"] as? String ?? ""
            print("👋 Usuario desconectado: \(userName) de sala \(room)")
            DispatchQueue.main.async {
                self.presenceDelegate?.didMemberLeave(userId: userId, userName: userName, room: room)
            }

        default:
            break
        }
    }

}



extension WebRTCManager {
    func createOffer(onSDP: @escaping (RTCSessionDescription) -> Void) {

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: ["OfferToReceiveAudio": "false"],
            optionalConstraints: nil
        )

        peerConnection?.offer(for: constraints) { sdp, error in
            guard let sdp = sdp else { return }

            Task {
                do {
                    try await self.peerConnection?.setLocalDescription(sdp)
                    
                    await WebSocketSignaling.shared.send([
                              "type": "offer",
                              "sdp": sdp.sdp
                          ])
                } catch {
                    print("Error setting local description:", error)
                }
            }
            onSDP(sdp)
        }
    }
}

extension Notification.Name {
    static let playbackSync = Notification.Name("playbackSync")
}
extension WebRTCManager {

    func createPeerConnection() {

        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        ]

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": "true"]
        )

        peerConnection = factory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        )
    }
    func setRemoteOffer(_ offer: RTCSessionDescription) {

        peerConnection?.setRemoteDescription(offer) { error in
            if let error = error {
                print("❌ Error setRemoteOffer:", error)
                return
            }

            print("✅ Remote OFFER set")

            self.createAnswer()
        }
    }
    private func createAnswer() {

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: ["OfferToReceiveAudio": "false"],
            optionalConstraints: nil
        )

        peerConnection?.answer(for: constraints) { sdp, error in
            if let error = error {
                print("❌ Error createAnswer:", error)
                return
            }

            guard let sdp = sdp else { return }
         

            Task {
                do {
                    try await self.peerConnection?.setLocalDescription(sdp)
                } catch {
                    print("Error setting local description:", error)
                }
            }
          

            WebSocketSignaling.shared.send([
                "type": "answer",
                "sdp": sdp.sdp
            ])

            print("📤 ANSWER enviado")
        }
    }

}

extension WebRTCManager {

    func createDataChannel() {
        let config = RTCDataChannelConfiguration()
        config.isOrdered = true
        config.maxRetransmits = 0

        dataChannel = peerConnection?.dataChannel(
            forLabel: "syncwave-data",
            configuration: config
        )

        dataChannel?.delegate = self
    }
}
extension WebRTCManager: RTCDataChannelDelegate {

    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("DataChannel state:", dataChannel.readyState)
    }

    func dataChannel(_ dataChannel: RTCDataChannel,
                     didReceiveMessageWith buffer: RTCDataBuffer) {

        guard let state = try? JSONDecoder()
            .decode(PlaybackState.self, from: buffer.data) else { return }

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .playbackSync,
                object: state
            )
        }
    }
}


extension WebRTCManager: RTCPeerConnectionDelegate {

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange stateChanged: RTCSignalingState) {
        // no-op
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didAdd stream: RTCMediaStream) {
        // deprecated, no-op
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove stream: RTCMediaStream) {
        // deprecated, no-op
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        // no-op
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceConnectionState) {
        // no-op
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCIceGatheringState) {
        // no-op
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didGenerate candidate: RTCIceCandidate) {
        
        WebSocketSignaling.shared.send([
                "type": "ice-candidate",
                "candidate": candidate.sdp,
                "sdpMLineIndex": candidate.sdpMLineIndex,
                "sdpMid": candidate.sdpMid ?? ""
            ])
        // enviar candidate a backend
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didRemove candidates: [RTCIceCandidate]) {
        // no-op
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didOpen dataChannel: RTCDataChannel) {
        self.dataChannel = dataChannel
        self.dataChannel?.delegate = self
    }
}

