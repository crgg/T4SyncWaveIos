//
//  GroupService.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/17/25.
//

import Foundation

final class GroupService {
    static let shared = GroupService()
    private init() {}
    
    
    private let baseURL = URL(string: "https://t4videocall.t4ever.com")!
    
    
    func list() async throws -> GroupResponse {
        try await APICore.shared.request(
            baseURL: baseURL,
            endpoint: "/api/groups/list",
            requiredAuth: true
        )
    }
    func listToListener() async throws -> GroupResponse {
        try await APICore.shared.request(
            baseURL: baseURL,
            endpoint: "/api/groups/groups-listens",
            requiredAuth: true
        )
    }
    
    
//    func create(name: String, description: String?) async throws -> GroupModel {
//        try await APICore.shared.request(
//            baseURL: baseURL,
//            endpoint: "/api/groups/create",
//            method: "POST",
//            body: ["name": name, "description": description]
//        )
//    }
    
    
    func update(id: String, name: String) async throws -> GroupModel {
        try await APICore.shared.request(
            baseURL: baseURL,
            endpoint: "/api/groups/\(id)",
            method: "PUT",
            body: ["name": name]
        )
    }
    
    
    func delete(id: String) async throws {
        let _: EmptyResponse = try await APICore.shared.request(
            baseURL: baseURL,
            endpoint: "/api/groups/delete",
            method: "POST",
            body : ["id" : id]
        )
    }
}

extension GroupService {
    
    
    func create(name: String) async throws -> GroupReponseCreate {
        try await APICore.shared.request(
            baseURL: baseURL,
            endpoint: "/api/groups/create",
            method: "POST",
            body: ["name": name],
            requiredAuth: true
        )
       
    }


    func addMember(request: AddMemberRequest) async throws  -> AddMemberResponse {
        try await APICore.shared.request(
            baseURL: baseURL,
            endpoint: "/api/groups/add-member",
            method: "POST",
            body: request,
            requiredAuth: true
        )
    }
    
    /// Join a group using 6-character code
    func joinByCode(_ code: String) async throws -> JoinGroupResponse {
        try await APICore.shared.request(
            baseURL: baseURL,
            endpoint: "/api/groups/join",
            method: "POST",
            body: ["code": code],
            requiredAuth: true
        )
    }
}


struct EmptyResponse: Decodable {}

extension GroupService {
    func getGroup(id: String) async throws -> GroupResponseDetail {
        try await APICore.shared.request(
            baseURL: URL(string: "https://t4videocall.t4ever.com")!,
            endpoint: "/api/groups/get/\(id)",
            requiredAuth: true
        )


    }

    func getRoomState(roomId: String) async throws -> RoomStateResponse {
        try await APICore.shared.request(
            baseURL: baseURL,
            endpoint: "/api/room-state/\(roomId)",
            requiredAuth: true
        )
    }
}
