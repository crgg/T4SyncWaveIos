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
    
    private let maxEmailLength = 100
    
    @State private var email = ""
    @State private var localError: String?
    @State private var isLoading = false
    let groupId: String
    
    // Validar formato de email
    private var isValidEmail: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        guard trimmed.count <= maxEmailLength else { return false }
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: trimmed)
    }
    
    // Email excede longitud máxima
    private var isEmailTooLong: Bool {
        email.count > maxEmailLength
    }
    
    // Mostrar error solo si hay texto y no es válido
    private var shouldShowEmailError: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && !isValidEmail && !isEmailTooLong
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("User email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: email) { _, newValue in
                            // Limitar longitud
                            if newValue.count > maxEmailLength {
                                email = String(newValue.prefix(maxEmailLength))
                            }
                            // Limpiar errores al escribir
                            localError = nil
                            vm.error = nil
                        }
                    
                    // Contador de caracteres
                    HStack {
                        Spacer()
                        Text("\(email.count)/\(maxEmailLength)")
                            .font(.caption2)
                            .foregroundColor(email.count >= maxEmailLength - 10 ? .orange : .secondary)
                    }
                }
                
                // Error de formato de email
                if shouldShowEmailError {
                    Text("Invalid email format")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                
                // Error de longitud
                if isEmailTooLong {
                    Text("Email too long (max \(maxEmailLength) characters)")
                        .foregroundColor(.red)
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
