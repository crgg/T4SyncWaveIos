//
//  ListenerView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/18/25.
//

import SwiftUI

struct ListenerView: View {
    @StateObject private var vm = GroupsViewListenerModel()
    @State private var showJoin = false
    
    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Loading groups...")
                } else if vm.groups.isEmpty { 
                    // Listener empty state - only show join option
                    EmptyListenerView {
                        showJoin = true
                    }
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
            .navigationTitle("Listening")
            .toolbar {
                Button {
                    showJoin = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
            }
            .task { await vm.load() }
            .sheet(isPresented: $showJoin) {
                JoinGroupView { code in
                    await joinGroup(code: code)
                }
            }
            
        } .tabItem {     
            Label("Listening", systemImage: "headphones")
        }
    }
    
    private func joinGroup(code: String) async -> Bool {
        do {
            let response = try await GroupService.shared.joinByCode(code)
            if response.status, let group = response.group {
                if !vm.groups.contains(where: { $0.id == group.id }) {
                    vm.groups.insert(group, at: 0)
                }
                return true
            }
            return false
        } catch {
            return false
        }
    }
}

// Empty state for listeners
struct EmptyListenerView: View {
    let onJoin: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "headphones")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("No Groups Yet")
                .font(.title2.bold())
            
            Text("Join a group with a code to start listening with friends")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                onJoin()
            } label: {
                Label("Join with Code", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

#Preview {
    ListenerView()
}
