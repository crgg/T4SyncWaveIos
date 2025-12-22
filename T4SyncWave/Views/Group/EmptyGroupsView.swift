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
            Image(systemName: "shareplay")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            
            Text("No Groups Yet")
                .font(.title2.bold())
            
            
            Text("Create your first DJ group and start syncing music")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                onCreate()
            } label: {
                Label("Create Group", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity)
            }
                .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
        }
        .padding()
    }
}
#Preview {
    EmptyGroupsView {
        print("Create")
    }
}
