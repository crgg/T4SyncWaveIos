//
//  EmptyGroupsView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import SwiftUI

struct EmptyGroupsView: View {
    let onCreate: () -> Void
    
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            
            Text("No Groups Yet")
                .font(.title2.bold())
            
            
            Text("Create your first DJ group and start syncing music")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            
            Button("Create Group", action: onCreate)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
#Preview {
    EmptyGroupsView {
        print("El usuario quiere crear un grupo: Acción simulada con éxito")
    }
}
