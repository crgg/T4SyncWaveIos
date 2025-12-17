//
//  User.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation

 
struct User: Codable, Identifiable {
    let id: String
    let name: String
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}
struct Room: Identifiable, Codable, Equatable {
    let id: String
    let name: String
}
