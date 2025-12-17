//
//  WebSocketSignaling.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation
import Combine

final class WebSocketSignaling: NSObject, ObservableObject {

    static let shared = WebSocketSignaling()

    // 🔴 AQUÍ VA TU BACKEND URL
    private let url = URL(string: "wss://t4videocall.t4ever.com/sfu-video/ws")!

    private var socket: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)

    override init() {
        super.init()
    }

    func connect(room: String, userName: String) {
        socket = session.webSocketTask(with: url)
        socket?.resume()

        send([
            "type": "join",
            "room": room,
            "userName": userName
        ])

        listen()
    }

    func send(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let text = String(data: data, encoding: .utf8) else { return }

        socket?.send(.string(text)) { error in
            if let error = error {
                print("❌ WS send error:", error)
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
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        guard case .string(let text) = message else { return }

           print("📩 WS recibido:", text)

           guard
               let data = text.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
           else { return }
           print("📩send to webrtc")
           WebRTCManager.shared.handleSignaling(json)
    }
}
