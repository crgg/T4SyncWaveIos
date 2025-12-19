//
//  AddMemberView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import SwiftUI

struct AddMemberView: View {
    @EnvironmentObject var vm : GroupDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    
    @State private var email = ""
    @State private var localError: String?
    @State private var isLoading = false
    let groupId: String
    
    // Validar formato de email
    private var isValidEmail: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: trimmed)
    }
    
    // Mostrar error solo si hay texto y no es válido
    private var shouldShowEmailError: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !isValidEmail
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("User email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: email) { _, _ in
                        // Limpiar errores al escribir
                        localError = nil
                        vm.error = nil
                    }
                
                // Error de formato de email
                if shouldShowEmailError {
                    Text("Invalid email format")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                
                // Error del servidor o local
                if let error = localError ?? vm.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("Add Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addMember()
                    }
                    .disabled(!isValidEmail || isLoading)
                }
            }
        }
    }
    
    private func addMember() {
        // Validar antes de enviar
        guard isValidEmail else {
            localError = "Please enter a valid email"
            return
        }
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            // Normalizar email
            let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
            let response = await vm.addMember(groupId: groupId, email: normalizedEmail)
            if response {
                dismiss()
            }
        }
    }
}

//#Preview {
//    AddMemberView(groupId: "00000000-0000-0000-0000-000000000000")
//}
