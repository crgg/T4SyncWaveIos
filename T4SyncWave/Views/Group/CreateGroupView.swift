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
    
    
    let onSave: (String) async -> Void
    
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Group name", text: $name)
            }
            .navigationTitle("New Group")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            await onSave(name)
                            isCreating = false
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || isCreating)
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
