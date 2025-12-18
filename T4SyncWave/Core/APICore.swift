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
enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case serverError(statusCode: Int, data: Data?) // Añadimos 'data' al error
    case customError(message: String)
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
            
            
            // Manejo específico del 401 (No autorizado)
            if httpResponse.statusCode == 401 {
                
                if endpoint.contains("auth/login") || errorBody.contains("Invalid credentials") {
                    // No lanzamos un APIError.serverError(401)
                    // En su lugar, lanzamos un error que el ViewModel pueda interpretar como LoginError.
                    
                    // Opción 1 (Recomendada): Lanzar un error decodificado
                    // Intentamos decodificar el cuerpo 401 a un modelo de error (ej: ErrorResponse)
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        // Asumiendo que ErrorResponse tiene la propiedad 'msg' o 'message'
                        throw LoginError.invalidCredentials(message: errorResponse.msg ?? "Unknown error")
                    }
                    
                    // Si la decodificación falla, podemos usar el String.
                    throw LoginError.invalidCredentials(message: "Invalid credentials")
                }
                
                // Aquí puedes lanzar una notificación para el AppStateManager para cerrar la sesión
                // ...
                print("🚨 401 Unauthorized: Sesión Expirada. Disparando notificación de logout.")
                
                NotificationCenter.default.post(name: .userSessionExpired, object: nil)
            }
        
        
            throw APIError.serverError(statusCode: httpResponse.statusCode, data: data)
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
 
}
