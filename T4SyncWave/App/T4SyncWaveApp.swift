//
//  T4SyncWaveApp.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import SwiftUI
import SwiftData

@main
struct T4SyncWaveApp: App {
    @StateObject var appState = AppStateManager().self
    @StateObject private var session = SessionManager.shared
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        
        WindowGroup {
            AppRootView()
                .environmentObject(appState)
        }
        .modelContainer(sharedModelContainer)
    }
    //            LibraryView(roomId: "bulla", userName: "Fco3")
}
