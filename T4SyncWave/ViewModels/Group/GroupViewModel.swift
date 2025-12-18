//
//  GroupViewModel.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation
import Combine

@MainActor
final class GroupsViewModel: ObservableObject {
    
    
    @Published var groups: [GroupModel] = []
    @Published var isLoading = false
    @Published var showCreate = false
    @Published var error: String?
    
    
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await GroupService.shared.list()
            groups = response.groups
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    
    func create(name: String) async {
        do {
            let new = try await GroupService.shared.create(name: name)
          
                self.groups.insert(new.group, at: 0)
           
        
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    
    func delete(id: UUID) async {
        try? await GroupService.shared.delete(id: id.uuidString)
        groups.removeAll { $0.id == id }
    }
}
