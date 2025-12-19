//
//  RegisterView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import Foundation
import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var appState: AppStateManager
    @StateObject private var vm = AuthViewModel()
    
    // Límites de caracteres
    private let maxNameLength = 50
    private let maxEmailLength = 100
    private let maxPasswordLength = 50
    
    var body: some View {
        VStack(spacing: 24) {
            
            
            Spacer()
            
            
            Text("Create Account")
                .font(.largeTitle.bold())
            
            
            VStack(spacing: 16) {
                TextField("Name", text: $vm.name)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: vm.name) { _, newValue in
                        if newValue.count > maxNameLength {
                            vm.name = String(newValue.prefix(maxNameLength))
                        }
                    }
                
                
                TextField("Email", text: $vm.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: vm.email) { _, newValue in
                        if newValue.count > maxEmailLength {
                            vm.email = String(newValue.prefix(maxEmailLength))
                        }
                    }
                
                
                SecureField("Password", text: $vm.password)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: vm.password) { _, newValue in
                        if newValue.count > maxPasswordLength {
                            vm.password = String(newValue.prefix(maxPasswordLength))
                        }
                    }
            }
            
            
            if let error = vm.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            
            Button {
                Task { await vm.register(appState: appState) }
            } label: {
                if vm.isLoading {
                    ProgressView()
                } else {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.name.isEmpty || vm.email.isEmpty || vm.password.isEmpty || vm.isLoading)
            
            
            Spacer()
        }
        .padding()
    }
}
#Preview {
    RegisterView()
    
}
