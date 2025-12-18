//
//  User.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation


struct User: Decodable {
    let id: String
    let name: String
    let email: String
}


struct UserSession: Codable {
    let id: String
    let name: String
    let email: String
    let role: String?
    let avatar: String?
}

struct AuthResponse: Decodable {
    let message : String
    let user: User
    let token: String
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
    let token_device: String
}

struct RegisterRequest: Encodable {
    let name: String
    let email: String
    let password: String
}

struct Room: Identifiable, Codable, Equatable {
    let id: String
    let name: String
}

