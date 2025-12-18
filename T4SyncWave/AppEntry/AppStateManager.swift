//
//  AppStateManager.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import Foundation
 

import SwiftUI
import Combine
// El manager central para el estado de la aplicación
@MainActor
class AppStateManager: ObservableObject {
  
    @Published var isLoggedIn: Bool
    
    init() {
        // 1) carga estado persistente
        self.isLoggedIn = UserDefaults.standard.isLoggedIn()
        
        // 2) escucha sesión expirada (401)
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .userSessionExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.forceLogout()
            }
        }
    }
    
    func setLoggedIn(_ value: Bool) {
        self.isLoggedIn = value
        UserDefaults.standard.setLoggedIn(value)
    }
  
    func logout() {
        
        self.setLoggedIn(false)
//    s    let result =   KeychainManager.deleteAuthToken()
        KeychainManager.clear()
        SessionStore.shared.clear()

         
    }
    
    // Lógica de cierre de sesión
    func forceLogout() {
        print("⚠️ Sesión expirada por el servidor (401).")
        logout()
      
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
