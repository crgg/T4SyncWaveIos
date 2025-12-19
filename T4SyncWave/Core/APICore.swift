//
//  APICore.swift
//  T4SyncWe
//
//  Created by Ramon Gajardo on 12/17/25.
//

 
import Foundation
//enum APIError: Error {
//    case invalidURL
//    case invalidResponse
//    case decodingError(Error)
//    case serverError(statusCode: Int)
//}
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case serverError(statusCode: Int, message: String)
    case customError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        case .serverError(_, let message):
            return message
        case .customError(let message):
            return message
        }
    }
}
class APICore {
    
    static let shared = APICore()
    
    private init() {}
    
    private let maxRetries = 2
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30   // segundos
        config.timeoutIntervalForResource = 60  // descarga total
        return URLSession(configuration: config)
    }()
    
   func request<T: Decodable>(
           baseURL: URL,
           endpoint: String,
           method: String = "GET",
           body: Encodable? = nil,
           requiredAuth: Bool = true
       ) async throws -> T {
           return try await requestWithRetry(
               baseURL: baseURL,
               endpoint: endpoint,
               method: method,
               body: body,
               attempt: 0,
               requiredAuth: requiredAuth
           )
       }
    
    
    // request with retry
    private func requestWithRetry<T: Decodable>(
           baseURL: URL,
           endpoint: String,
           method: String,
           body: Encodable?,
           attempt: Int,
           requiredAuth: Bool = true
       ) async throws -> T {

           do {
               return try await performRequest(
                   baseURL: baseURL,
                   endpoint: endpoint,
                   method: method,
                   body: body,
                   requiredAuth: requiredAuth
               )
           } catch let APIError.serverError(statusCode, _) where attempt < maxRetries && shouldRetry(statusCode: statusCode) {
               print("🔁 Retry \(attempt + 1) para \(endpoint)")
               return try await requestWithRetry(
                   baseURL: baseURL,
                   endpoint: endpoint,
                   method: method,
                   body: body,
                   attempt: attempt + 1
               )
           } catch {
               throw error
           }
       }
    
    func performRequest<T: Decodable>(
        baseURL: URL,
        endpoint: String,
        method: String,
        body: Encodable?,
        requiredAuth: Bool
        ) async throws -> T {
        
        try Task.checkCancellation()

        let url = baseURL.appendingPathComponent(endpoint)
        print("➡️ URL: \(url.absoluteString)")
        
        print("URL FINAL DE LLAMADA: \(url.absoluteString)") // <<-- ¡REVISA ESTO!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
            
        // if exist a token
        if requiredAuth, let token = KeychainManager.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
            
        request.httpMethod = method
                 
        // 1. CODIFICACIÓN DEL BODY (Si hay body)
        if let body = body {
            do {
                let requestData = try JSONEncoder().encode(body)
                request.httpBody = requestData
                // DEBUG: Muestra el JSON que se está enviando al servidor
                print("➡️ Petición a \(url.absoluteString) con body: \(String(data: requestData, encoding: .utf8) ?? "N/A")")
            } catch {
                print("❌ ERROR DE CODIFICACIÓN (Request Body): \(error.localizedDescription)")
                throw APIError.decodingError(error)
            }
        } else {
            print("➡️ Petición a \(url.absoluteString) (Sin Body)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ ERROR DE RESPUESTA: La respuesta no es HTTP.")
            throw APIError.invalidResponse
        }
        
        // 2. DEBUG: Muestra el estado HTTP
        print("⬅️ Respuesta HTTP Status: \(httpResponse.statusCode)")

        // 3. MANEJO DE ERRORES HTTP (4xx o 5xx)
        guard (200...299).contains(httpResponse.statusCode) else {
            
            // DEBUG: Imprime los datos del cuerpo del error (si el backend envía JSON con el mensaje de error)
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            print("🔴 ERROR SERVER BODY (\(httpResponse.statusCode)): \(errorBody)")
            
            // Intentar extraer el mensaje de error del backend
            let errorMessage = extractErrorMessage(from: data, statusCode: httpResponse.statusCode)
            
            // Manejo específico del 401 (No autorizado)
            if httpResponse.statusCode == 401 {
                
                if endpoint.contains("auth/login") || errorBody.contains("Invalid credentials") {
                    throw LoginError.invalidCredentials(message: errorMessage)
                }
                
                print("🚨 401 Unauthorized: Sesión Expirada. Disparando notificación de logout.")
                NotificationCenter.default.post(name: .userSessionExpired, object: nil)
            }
            
            // Para 400, intentar decodificar la respuesta (puede tener status: false con msg)
            if httpResponse.statusCode == 400 {
                do {
                    if let rawJSON = String(data: data, encoding: .utf8) {
                        print("🟢 Respuesta 400 JSON: \(rawJSON.prefix(300))...")
                    }
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    print("❌ ERROR DE DECODIFICACIÓN (JSON a Swift Model): \(error.localizedDescription)")
                    throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
                }
            }
        
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        // 4. DECODIFICACIÓN EXITOSA (200-299)
        do {
            // DEBUG: Muestra el JSON crudo que intentaremos decodificar
            if let rawJSON = String(data: data, encoding: .utf8) {
                print("🟢 Respuesta Exitosa JSON: \(rawJSON.prefix(300))...")
            }
            
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            // 5. DEBUG: Muestra el error de decodificación detallado
            print("❌ ERROR DE DECODIFICACIÓN (JSON a Swift Model): \(error.localizedDescription)")
            print("Tipo de Modelo Esperado: \(T.self)")
            throw APIError.decodingError(error)
        }
    }
    private func shouldRetry(statusCode: Int?) -> Bool {
        guard let statusCode else { return true } // error de red
        return (500...599).contains(statusCode)
    }
    
    /// Extrae el mensaje de error del JSON del backend
    private func extractErrorMessage(from data: Data, statusCode: Int) -> String {
        // Intentar parsear el JSON una sola vez
        if let errorResponse = try? JSONDecoder().decode(ErrorMessageResponse.self, from: data) {
            // Prioridad: msg > message > error
            if let msg = errorResponse.msg, !msg.isEmpty {
                return msg
            }
            if let message = errorResponse.message, !message.isEmpty {
                return message
            }
            if let error = errorResponse.error, !error.isEmpty {
                return error
            }
        }
        
        // Si no se puede parsear, intentar mostrar el raw body
        if let rawString = String(data: data, encoding: .utf8), !rawString.isEmpty {
            // Si es un string simple de error
            if rawString.count < 200 {
                return rawString
            }
        }
        
        // Mensaje genérico con código
        return "Server error (code: \(statusCode))"
    }
}

// Modelo flexible para parsear mensajes de error del backend
private struct ErrorMessageResponse: Decodable {
    let msg: String?
    let message: String?
    let error: String?
    let status: Bool?
}
