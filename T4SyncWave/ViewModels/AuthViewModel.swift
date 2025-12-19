//
//  AuthViewModel.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    
    
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var currentUser: UserSession?
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    
    private let service = AuthService.shared
    
   
    func login(appState : AppStateManager ) async {
        guard isValidEmail(email) else {
            errorMessage = "Invalid email format"
            return
        }
        
        isLoading = true
        
        defer { isLoading = false }
        
        errorMessage = nil
        
        do {
            
            let device_token = KeychainManager.getDeviceToken()
            print("device token is \(device_token ?? "")")
            let credentials = LoginRequest(email: email, password: password, token_device: device_token ?? "")
            
            let response = try await service.login(credential: credentials)
            
            if response.token.isEmpty {
                errorMessage = "Error the server, code : 4545"
            }
            
            let resulKeyAuthToken = KeychainManager.saveAuthToken(token: response.token )
            print("result the key token is \(resulKeyAuthToken)")

            appState.setLoggedIn(true)
            
            saveSession(response)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    
    func register(appState: AppStateManager) async {
        guard !name.isEmpty else {
            errorMessage = "Name is required"
            return
        }
        guard isValidEmail(email) else {
            errorMessage = "Invalid email format"
            return
        }
        
        
        isLoading = true
        defer { isLoading = false }
        
        errorMessage = nil
        
        do {
            let response = try await service.register(
                name: name,
                email: email,
                password: password
            )
            
            // Guardar token (igual que en login)
            if response.token.isEmpty {
                errorMessage = "Error from server, code: 4546"
                return
            }
            
            let resultKeyAuthToken = KeychainManager.saveAuthToken(token: response.token)
            print("Register - result key token is \(resultKeyAuthToken)")
            
            // Ir al Home
            appState.setLoggedIn(true)
            
            saveSession(response)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    
    private func saveSession(_ response: AuthResponse) {
        
        
        
        let user = response.user
        let session = UserSession(
            id: user.id,
            name: user.name,
            email: user.email,
            role: nil,
            avatar: ""
        )
        
        
        SessionStore.shared.saveUser(session)
        currentUser = session
         
        isAuthenticated = true
    }
    
    public func logout() {
        KeychainManager.clear()
        SessionStore.shared.clear()
        isAuthenticated = false
        currentUser = nil
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}
