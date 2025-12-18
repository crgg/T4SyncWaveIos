//
//  SessionManager.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/16/25.
//

 
import Foundation
import SwiftUI
import Combine

@MainActor
final class SessionManager: ObservableObject {

    static let shared = SessionManager()

    @Published var isLoggedIn: Bool = false
    @Published var user: User?

    private let tokenKey = "auth_token"

    private init() {
        loadSession()
    }

    // MARK: - Load existing session
    private func loadSession() {
        if let token = UserDefaults.standard.string(forKey: tokenKey) {
            // En producción puedes validar token
            self.isLoggedIn = true
//            self.user = User(name: "User", email: "user@example.com" , id: "1", token: token)
            print("🔐 Sesión restaurada")
        }
    }

    // MARK: - Login / Register
    func login(name: String) async {
        guard !name.isEmpty else { return }

        do {
            let url = URL(string: "https://YOUR_API/api/auth/register")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = ["name": name]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(AuthResponse.self, from: data)

            UserDefaults.standard.set(response.token, forKey: tokenKey)
            self.user = response.user
            self.isLoggedIn = true

            print("✅ Login OK:", response.user.name)

        } catch {
            print("❌ Login error:", error)
        }
    }

    // MARK: - Logout
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        self.user = nil
        self.isLoggedIn = false
    }
}
