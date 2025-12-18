//
//  AddMemberView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import SwiftUI

struct AddMemberView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    let groupId: UUID
    
    
    var body: some View {
        Form {
            TextField("User email", text: $email)
                .keyboardType(.emailAddress)
        }
        .navigationTitle("Add Member")
        .toolbar {
            Button("Add") {
                Task {
                    try? await GroupService.shared.addMember(groupId: groupId, email: email)
                    dismiss()
                }
            }
            .disabled(email.isEmpty)
        }
    }
}

//#Preview {
//    AddMemberView(groupId: "00000000-0000-0000-0000-000000000000")
//}
