//
//  GroupDetailView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import SwiftUI

struct GroupDetailView: View {
    let group: GroupModel
    
    
    var body: some View {
        List {
            Section("Info") {
                Label(group.code, systemImage: "qrcode")
                Label(group.is_playing ? "Playing" : "Stopped", systemImage: "play.circle")
            }
            
            
            Section {
                NavigationLink("Add member") {
                    AddMemberView(groupId: group.id)
                }
            }
        }
        .navigationTitle(group.name)
    }
}
#Preview {
//    GroupDetailView(group: GroupModel(id: U"90174548-e4e1-4eee-8046-67bc454e4492", name: "Ramodkj", code:  "CED3", is_active: true, current_track_id: nil, current_time_ms: 0, is_playing: false, created_by: nil, created_at: "2025-12-17T03:49:41.648Z", updated_at: "2025-12-17T03:49:41.648Z"))
}
