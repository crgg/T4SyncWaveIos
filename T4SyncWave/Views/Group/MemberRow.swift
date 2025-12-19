//
//  MemberRow.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/18/25.
//

import SwiftUI

struct MemberRow: View {

    let member: GroupMember

    var body: some View {
        HStack(spacing: 12) {

            Image(systemName: "person.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(member.role == .dj ? .blue : .gray)

            VStack(alignment: .leading) {
                Text(member.name)
                    .font(.body)
                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if member.role == .dj {
                Text("DJ")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.blue.opacity(0.15)))
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}



//#Preview {
//    MemberRow()
//}
