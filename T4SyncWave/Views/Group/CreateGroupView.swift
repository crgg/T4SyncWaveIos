//
//  CreateGroupView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var isCreating = false
    
    private let maxNameLength = 50
    
    let onSave: (String) async -> Void
    
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                TextField("Group name", text: $name)
                        .onChange(of: name) { _, newValue in
                            if newValue.count > maxNameLength {
                                name = String(newValue.prefix(maxNameLength))
                            }
                        }
                } footer: {
                    Text("\(name.count)/\(maxNameLength) characters")
                        .font(.caption)
                        .foregroundColor(name.count >= maxNameLength ? .orange : .secondary)
                }
            }
            .navigationTitle("New Group")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            await onSave(name.trimmingCharacters(in: .whitespaces))
                            isCreating = false
                        dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { dismiss() })
                        .disabled(isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}

#Preview {
    CreateGroupView { _ in 
        print("dale dael")
    }
}
