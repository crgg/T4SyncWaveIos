//
//  AppRootView.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import SwiftUI
 
struct AppRootView: View {
    @EnvironmentObject var appState: AppStateManager
    
    var body: some View {
        Group {
            if appState.isLoggedIn {
               MainTabView()
                  
                
            } else {
                LoginView()
                    
                    
            }
        }
    }
}
