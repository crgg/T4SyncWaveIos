//
//  RegisterView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import Foundation
import SwiftUI

struct RegisterView: View {
    @StateObject private var vm = AuthViewModel()
    
    
    var body: some View {
        VStack(spacing: 24) {
            
            
            Spacer()
            
            
            Text("Create Account")
                .font(.largeTitle.bold())
            
            
            VStack(spacing: 16) {
                TextField("Name", text: $vm.name)
                    .textFieldStyle(.roundedBorder)
                
                
                TextField("Email", text: $vm.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(.roundedBorder)
                
                
                SecureField("Password", text: $vm.password)
                    .textFieldStyle(.roundedBorder)
            }
            
            
            if let error = vm.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            
            Button {
                Task { await vm.register() }
            } label: {
                if vm.isLoading {
                    ProgressView()
                } else {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            
            
            Spacer()
        }
        .padding()
    }
}
#Preview {
    RegisterView()
    
}
