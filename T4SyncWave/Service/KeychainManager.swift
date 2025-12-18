//
//  APIManager.swift
//  t4ever
//
//  Created by Ramon Gajardo on 12/11/25.
//

import Foundation
 
import Security

class KeychainManager {
    
    // Identificador único para nuestro token en el Keychain
    private static let service = "com.t4syncwave.authToken" // Usa tu bundle ID o un nombre único
    private static let deviceTokenService = "com.t4syncwave.deviceToken"
    
    
    
        static func saveDeviceToken(token: String) -> OSStatus {
            guard let data = token.data(using: .utf8) else { return errSecInvalidData }
            
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: deviceTokenService,
                kSecAttrAccount as String: "device_registration"
            ]
            
            // ... (misma lógica de SecItemUpdate y SecItemAdd que en saveAuthToken) ...
            
            // Si el token ya existe, actualizarlo. Si no, añadirlo.
            let attributes: [String: Any] = [kSecValueData as String: data]
            var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            
            if status == errSecItemNotFound {
                let addQuery = query + attributes
                status = SecItemAdd(addQuery as CFDictionary, nil)
            }
            
            return status
        }
        
        // Obtener el Device Token
        static func getDeviceToken() -> String? {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: deviceTokenService,
                kSecAttrAccount as String: "device_registration",
                kSecReturnData as String: kCFBooleanTrue!,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            
            if status == errSecSuccess, let data = item as? Data {
                return String(data: data, encoding: .utf8)
            }
            
            return nil
        }


    // --- GUARDAR (Crea o actualiza un token) ---
    static func saveAuthToken(token: String) -> OSStatus {
        guard let data = token.data(using: .utf8) else { return errSecInvalidData }
        
        // 1. Definir el Query base para el token
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "auth_user_session" // Un nombre de cuenta para este item
        ]
        
        // 2. Intentar actualizar (si ya existe)
        let attributes: [String: Any] = [kSecValueData as String: data]
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        // 3. Si no se pudo actualizar (porque no existe), lo agregamos
        if status == errSecItemNotFound {
            let addQuery = query + attributes
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }
        
        return status
    }

    // --- RECUPERAR (Obtiene el token) ---
    static func getAuthToken() -> String? {
        // 1. Definir el Query para buscar el item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "auth_user_session",
            kSecReturnData as String: kCFBooleanTrue!, // Queremos el dato de vuelta
            kSecMatchLimit as String: kSecMatchLimitOne // Solo queremos uno
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        // 2. Si es exitoso, procesar el resultado
        if status == errSecSuccess, let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }
        
        return nil // No se encontró o falló
    }

    // --- ELIMINAR (Cierra la sesión) ---
    static func deleteAuthToken() -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "auth_user_session"
        ]
        
        // Elimina el item que coincide con el query
        return SecItemDelete(query as CFDictionary)
    }
    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// Extensión para unir diccionarios (hace el código más legible)
private func + (lhs: [String: Any], rhs: [String: Any]) -> [String: Any] {
    var result = lhs
    rhs.forEach { result[$0.key] = $0.value }
    return result
}
