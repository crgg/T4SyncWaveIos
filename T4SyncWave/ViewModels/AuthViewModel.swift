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

    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?

    func login(email: String, password: String) async {
        isLoading = true
        do {
            user = try await AuthService.shared.login(email: email, password: password)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
