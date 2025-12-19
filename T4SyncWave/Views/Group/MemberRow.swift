//
//  MemberRow.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/18/25.
//

import SwiftUI

struct MemberRow: View {

    let member: GroupMember
    var isOnline: Bool = false // Will be updated when backend sends presence events

    var body: some View {
        HStack(spacing: 12) {

            // Avatar with online indicator
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(member.role == .dj ? .blue : .gray)
                
                // Online status indicator
                Circle()
                    .fill(isOnline ? Color.green : Color.gray.opacity(0.5))
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color(UIColor.systemBackground), lineWidth: 2)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.name)
                        .font(.body)
                    
                    if isOnline {
                        Text("listening")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
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
