//
//  ListenerView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/18/25.
//

import SwiftUI

struct ListenerView: View {
    @StateObject private var vm = GroupsViewListenerModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Loading groups...")
                } else if vm.groups.isEmpty { 
                    EmptyGroupsView { vm.showCreate = true }
                } else {
                    List {
                        ForEach(vm.groups ) { group in
                            NavigationLink(group.name) {
                                GroupDetailView(groupId: group.id.uuidString, listener: true)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Groups")
            .task { await vm.load() }
            
        } .tabItem {
            Label("Groups", systemImage: "airpods.max")
        }
    }
}

#Preview {
    ListenerView()
}
