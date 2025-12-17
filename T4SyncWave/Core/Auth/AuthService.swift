//
//  AuthService.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation
 
final class AuthService {

    static let shared = AuthService()
    
    private init() {}

    func login(email: String, password: String) async throws -> User {
        // Llamada a tu backend
        // POST /login
        fatalError("Implement")
    }

    func register(email: String, password: String) async throws -> User {
        // POST /register
        fatalError("Implement")
    }
}
