import SwiftUI

struct LibraryView: View {

    @StateObject private var vm = LibraryViewModel()
    init(roomId : String , userName: String) {
        _vm = StateObject(wrappedValue: LibraryViewModel(roomId: roomId, userName: userName))
    }
 
    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.tracks) { track in
                    HStack {
                        Image(systemName: "music.note")
                        Text(track.title)
                        Spacer()
                        if vm.selectedTrack == track {
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
        }
    }
}

