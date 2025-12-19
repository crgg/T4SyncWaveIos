//
//  GroupsListView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import SwiftUI

struct GroupsListView: View {
    @StateObject private var vm = GroupsViewModel()
    
    
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
                                GroupDetailView(groupId: group.id.uuidString)
                            }
                        }
                        .onDelete { indexSet in
                            let ids = indexSet.map { vm.groups[$0].id }
                            
                            vm.groups.remove(atOffsets: indexSet)
                            
                            Task {
                                for id in ids {
                                    await vm.delete(id: id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                Button {
                    vm.showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .task { await vm.load() }
            .sheet(isPresented: $vm.showCreate) {
                CreateGroupView { name in
                    await vm.create(name: name)
                }
            }
        }
    }
}

#Preview {
    GroupsListView()
}
