//
//  MainTabView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
            LibraryView(context: .personal)        
            ProfileView()
            
        }
    }
}

#Preview {
    MainTabView()
}
