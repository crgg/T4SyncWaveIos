//
//  SessionStore.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/18/25.
//

import Foundation
final class SessionStore {
    static let shared = SessionStore()
    private init() {}
    
    
    private let userKey = "current_user"
    
    
    func saveUser(_ user: UserSession) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }
    
    
    func loadUser() -> UserSession? {
        guard let data = UserDefaults.standard.data(forKey: userKey) else {
            return nil
        }
        return try? JSONDecoder().decode(UserSession.self, from: data)
    }
    
    
    func clear() {
        UserDefaults.standard.removeObject(forKey: userKey)
    }
}
