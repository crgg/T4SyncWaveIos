//
//  RoomsViewModel.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/16/25.
//

import Foundation
 
import SwiftUI
import Combine
@MainActor
final class RoomsViewModel: ObservableObject {

    @Published var rooms: [Room] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiBase = "https://YOUR_API"
    private let session: SessionManager

    init(session: SessionManager) {
        self.session = session
        Task { await loadRooms() }
    }

    // MARK: - Load rooms
    func loadRooms() async {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let url = URL(string: "\(apiBase)/api/rooms")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)
            rooms = try JSONDecoder().decode([Room].self, from: data)
            print("👥 Rooms cargadas:", rooms.count)
        } catch {
            errorMessage = "Failed to load rooms"
            print("❌ loadRooms:", error)
        }
    }

    // MARK: - Create room
    func createRoom(name: String) async -> Room? {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else { return nil }

        do {
            let url = URL(string: "\(apiBase)/api/rooms")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["name": name])

            let (data, _) = try await URLSession.shared.data(for: request)
            let room = try JSONDecoder().decode(Room.self, from: data)

            rooms.append(room)
            return room
        } catch {
            print("❌ createRoom:", error)
            return nil
        }
    }

    // MARK: - Join room
    func joinRoom(roomId: String) async -> Room? {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else { return nil }

        do {
            let url = URL(string: "\(apiBase)/api/rooms/join")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["roomId": roomId])

            let (data, _) = try await URLSession.shared.data(for: request)
            let room = try JSONDecoder().decode(Room.self, from: data)

            rooms.append(room)
            return room
        } catch {
            print("❌ joinRoom:", error)
            return nil
        }
    }
}
