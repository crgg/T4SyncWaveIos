//
//  ProfileView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var appState: AppStateManager
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if  let user = SessionStore.shared.loadUser()  {
                        
                        Label( user.email  , systemImage: "envelope")
                    } else {
                        Label( "" , systemImage: "envelope")
                    }
                }
                
                
                Section {
                    Button(role: .destructive) {
                         
                        appState.logout()
                        
                    } label: {
                        Label("Logout", systemImage: "arrow.backward.circle")
                    }
                }
            }
            .navigationTitle("Profile")
        }
        .tabItem {
            Label("Profile", systemImage: "person.crop.circle")
        }
    }
}

#Preview {
    ProfileView()
}
