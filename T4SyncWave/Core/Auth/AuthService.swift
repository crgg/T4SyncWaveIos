//
//  AuthService.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation
enum LoginError: Error {
    
    // Este caso se usa cuando el servidor responde con 200 OK,
    // pero el JSON interno dice {"status": false, "msg": "..."}
    case invalidCredentials(message: String)
    
    // Puedes agregar más casos si tu servidor tiene otros errores de negocio
    // Por ejemplo:
    case userLocked(message: String)
    case missingData(message: String)
}
struct ErrorResponse : Codable {
    let status : Bool
    let msg : String?
}
    
    // Un error genérico para cualquier otro fallo que no sea de la lista anterior
@MainActor
final class AuthService {

    static let shared = AuthService()
    
    private init() {}

    private let baseURL = URL(string: "https://t4videocall.t4ever.com/api")!
    //email: String, password: String, token: String
    func login(credential : LoginRequest) async throws -> AuthResponse {
//        let body = LoginRequest(email: email, password: password, token_device: token )
        return try await APICore.shared.request(
            baseURL: baseURL,
            endpoint: "/auth/login",
            method: "POST",
            body: credential,
            requiredAuth: false
        )
    }

    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        let body = RegisterRequest(name: name, email: email, password: password)
        return try await APICore.shared.request(
            baseURL: baseURL,
            endpoint: "/auth/register",
            method: "POST",
            body: body
        )
    }
    
    
    
}
