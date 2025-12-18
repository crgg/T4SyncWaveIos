import SwiftUI

enum LibraryContext {
    case personal
    case group(groupId: String, roomId: String, userName: String)
}




struct LibraryView: View {
    
    let context: LibraryContext
    
//    let groupId: String?
    @StateObject private var vm : LibraryViewModel
    
    init(context: LibraryContext) {
        self.context = context
        
        switch context {
        case .personal:
            _vm = StateObject(
                wrappedValue: LibraryViewModel(
                    roomId: nil,
                    userName: nil
                )
            )
            
        case .group(let roomId, _, let userName):
            _vm = StateObject(
                wrappedValue: LibraryViewModel(
                    roomId: roomId,
                    userName: userName
                )
            )
        }
    }

    
//    init(groupId: String?, roomId : String , userName: String) {
//        self.groupId = groupId
//        _vm = StateObject(wrappedValue: LibraryViewModel(roomId: roomId, userName: userName))
//    }
 
    var body: some View {
        NavigationStack {
            if let track = vm.selectedTrack {
                
            }
            Slider(
                value: Binding(
                    get: { vm.syncTime() },
                    set: {
                        vm.audio.seek(to: $0)
//                        vm.broadcastState()
                    }
                ),
                in: 0...vm.audio.duration
            )
            List {
                ForEach(vm.tracks) { track in
                    HStack {
                        Image(systemName: "music.note")
                        Text(track.title)
                        Spacer()
                        if vm.selectedTrack?.id == track.id {
                            Image(systemName: "speaker.wave.2.fill")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.select(track)
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                Button {
                    vm.pickMP3()
                } label: {
                    Image(systemName: "plus")
                }
            }
        } .tabItem {
            Label("Library", systemImage: "music.note.list")
        }
    }
    // 🎯 Aquí está la magia
    private func handleSelection(_ track: AudioTrack) {
        vm.select(track)
        
        if case .group(let groupId, _, _) = context {
//            Task {
//                try? await GroupTrackService.shared.addTrack(id: groupId, name: String)
//                
//                ( groupId: groupId,  trackId: track.id )
//            }
        }
    }
}

