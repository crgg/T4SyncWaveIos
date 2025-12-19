//
//  HomeView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        GroupsListView()
            .tabItem {
                // shareplay = sync listening icon
                Label("My Groups", systemImage: "shareplay")
            }
    }
}

#Preview {
    HomeView()
}
