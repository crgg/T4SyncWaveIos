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
    let groupId: String
    
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("User email", text: $email)
                    .keyboardType(.emailAddress)
                if let error = vm.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
            }
            .navigationTitle("Add Member")
            .toolbar {
                Button("Add") {
                    Task {
                        //                    try? await GroupService.shared.addMember(groupId: groupId, email: email)
                        Task {
                            let response =  await vm.addMember(groupId: groupId, email: email)
                            if response {
                                dismiss()
                            }
                        }
                        
                    }
                }
                .disabled(email.isEmpty)
            }
        }
    }
}

//#Preview {
//    AddMemberView(groupId: "00000000-0000-0000-0000-000000000000")
//}
