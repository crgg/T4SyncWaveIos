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
        ZStack {
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
            
            // Toast overlay
            if let toast = vm.toastMessage {
                VStack {
                    Spacer()
                    ToastView(message: toast)
                        .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: vm.toastMessage)
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
                    isRepeatEnabled: vm.audio.isRepeatEnabled,
                    isListener: vm.isListener,
                    isMuted: vm.isMuted,
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
                    },
                    onToggleRepeat: {
                        vm.audio.toggleRepeat()
                    },
                    onToggleMute: {
                        vm.toggleMute()
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }
            .listRowSeparator(.hidden)
            
            // 🎧 DJ Section
            if let dj = vm.djMember {
                Section(header: Text("DJ")) {
                    DJRow(
                        member: dj,
                        isOnline: vm.onlineMembers.contains(dj.id)
                    )
                }
            }
            
            // 👥 LISTENERS
            Section(header: listenersHeader) {
                ForEach(vm.listenerMembers) { member in
                    MemberRow(
                        member: member,
                        isOnline: vm.onlineMembers.contains(member.id)
                    )
                }
                if !isListener {
                    Button {
                        showAddMember = true
                    } label: {
                        Label("Invite listener", systemImage: "plus")
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(group.name)
                    .font(.headline)
            }
        }
        .sheet(isPresented: $showLibrary, onDismiss: {
            // Recargar grupo cuando se cierre la biblioteca (por si se añadió canción)
            Task {
                await vm.load()
            }
        }) {
            LibraryView(
                context: .group(groupmodel: group)
            )
        }
        .sheet(isPresented: $showAddMember, onDismiss: {
            // Recargar grupo cuando se cierre (por si se añadió miembro)
            Task {
                await vm.load()
            }
        }) {
            AddMemberView(groupId: group.id)
        }
    }
    
    /// Header for listeners section
    private var listenersHeader: some View {
        HStack {
            Text("Listeners (\(vm.listenerMembers.count))")
            Spacer()
            if vm.onlineMembers.count > 0 {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("\(vm.onlineMembers.count) online")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }
}

// MARK: - DJ Row (Special styling for DJ)
struct DJRow: View {
    let member: GroupMember
    var isOnline: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with crown and online indicator
            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .top) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                    
                    // Crown for DJ
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                        .offset(y: -6)
                }
                
                // Online status
                Circle()
                    .fill(isOnline ? Color.green : Color.gray.opacity(0.5))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color(UIColor.systemBackground), lineWidth: 2)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.name)
                        .font(.body.bold())
                    
                    if isOnline {
                        Text("playing")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("DJ")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.blue))
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.fill.checkmark")
                .foregroundColor(.white)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.8))
        )
        .shadow(radius: 10)
    }
}

