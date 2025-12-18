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
    
    
    let onSave: (String) -> Void
    
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Group name", text: $name)
            }
            .navigationTitle("New Group")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onSave(name)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { dismiss() })
                }
            }
        }
    }
}

#Preview {
    CreateGroupView {_ in 
        print("dale dael")
        
    }
}
