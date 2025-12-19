//
//  GroupDetailView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import SwiftUI

struct GroupDetailView: View {

    @StateObject private var vm: GroupDetailViewModel
    @State private var showLibrary = false
    @State private var showAddMember = false
    private var isListener  = false
    

    init(groupId: String, listener: Bool = false) {
           _vm = StateObject(wrappedValue: GroupDetailViewModel(groupId: groupId, isListener: listener ))
        isListener = listener
    }

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView("Loading group...")
            } else if let group = vm.group {
                content(group)
                    .environmentObject(vm)
            } else {
                Text("Failed to load group")
            }
        }
        .task {
            // load the group
            await vm.load()
        }
    }
    
    private func content(_ group: GroupDetail) -> some View {
        List {
            
            // 🎧 NOW PLAYING
            Section {
                NowPlayingCard(
                    state: vm.nowPlayingState,
                    currentTime: vm.localCurrentTime,
                    duration: vm.duration,
                    isSeekEnabled: !vm.isListener,
                    onAddMusic: { showLibrary = true },
                    onPlayPause: {
                        vm.togglePlayPause()
                    },
                    onSeek: { seconds in
                        vm.seek(to: seconds)
                    },
                    onBackward: {
                        vm.skipBackward()
                    },
                    onForward: {
                        vm.skipForward()
                    }
                )
            }
            .listRowSeparator(.hidden)
            
            // 👥 MEMBERS
            Section(header: Text("Members (\(group.members.count))")) {
                ForEach(group.members) { member in
                    MemberRow(member: member)
                }
                if !isListener {
                    Button {
                        showAddMember = true
                    } label: {
                        Label("Add member", systemImage: "plus")
                    }
                }
            }
            
            // ℹ️ INFO
            Section("Group Info") {
                HStack {
                    Text("Code")
                    Spacer()
                    Text(group.code)
//                        .font(.monospaced())
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(group.name)
        .sheet(isPresented: $showLibrary) {
            
            LibraryView(
                context: .group(groupmodel:  group)
            )
        }
        .sheet(isPresented: $showAddMember) {
            AddMemberView(groupId: group.id)
               
                
        }
    }
}

