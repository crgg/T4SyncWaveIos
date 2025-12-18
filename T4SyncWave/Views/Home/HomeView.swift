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
                Label("Groups", systemImage: "person.3.fill")
            }
    }
}

#Preview {
    HomeView()
}
