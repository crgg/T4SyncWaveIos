//
//  MembersSection.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/18/25.
//

import SwiftUI

struct MembersSection: View {

    let members: [GroupMember]
    let onAddMember: () -> Void

    var body: some View {
        Section(
            header: Text("Members (\(members.count))")
        ) {
            ForEach(members) { member in
                MemberRow(member: member)
            }

            Button {
                onAddMember()
            } label: {
                Label("Add member", systemImage: "plus")
                    .foregroundColor(.blue)
            }
        }
    }
}


//#Preview {
//    MembersSection()
//}
