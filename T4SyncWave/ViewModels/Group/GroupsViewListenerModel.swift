//
//  GroupsViewListenerModel.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/18/25.
//

import Foundation
 
import Combine

@MainActor
final class GroupsViewListenerModel: ObservableObject {
    
    
    @Published var groups: [GroupModel] = []
    @Published var isLoading = false
    @Published var showCreate = false
    @Published var error: String?
    
    
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await GroupService.shared.listToListener()
            groups = response.groups
        } catch {
            self.error = error.localizedDescription
        }
    }
    
     
}
