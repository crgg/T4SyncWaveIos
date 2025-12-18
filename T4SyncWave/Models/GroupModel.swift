//
//  Group.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//
/*
 {
     "status": true,
     "groups": [
         {
             "id": "90174548-e4e1-4eee-8046-67bc454e4492",
             "name": "RamonDj",
             "code": "C0E78A",
             "is_active": true,
             "current_track_id": null,
             "current_time_ms": 0,
             "is_playing": false,
             "created_by": null,
             "created_at": "2025-12-17T03:49:41.648Z",
             "updated_at": "2025-12-17T03:49:41.648Z"
         },
         {
             "id": "811abc3e-5f91-40b3-8390-9d5b8cbf1de0",
             "name": "RamonDj",
             "code": "2FB8B9",
             "is_active": true,
             "current_track_id": null,
             "current_time_ms": 0,
             "is_playing": false,
             "created_by": null,
             "created_at": "2025-12-17T03:52:02.303Z",
             "updated_at": "2025-12-17T03:52:02.303Z"
         },
         {
             "id": "1f02aa83-4f66-421a-a210-9395cad8f268",
             "name": "RamonDj2",
             "code": "31A92F",
             "is_active": true,
             "current_track_id": null,
             "current_time_ms": 0,
             "is_playing": false,
             "created_by": "02e0fcfe-2e1b-41f8-a4de-726708e68ddc",
             "created_at": "2025-12-17T19:46:18.568Z",
             "updated_at": "2025-12-17T19:46:18.568Z"
         }
     ]
 }**/
import Foundation
 

// Estructura principal
struct GroupResponse: Codable {
    let status: Bool
    let groups: [GroupModel]
}

// Estructura del grupo
/**
 {"id":"90174548-e4e1-4eee-8046-67bc454e4492","name":"RamonDj","code":"C0E78A",
 "is_active":true,"current_track_id":null,"current_time_ms":0,"is_playing":false,"created_by":null,"created_at":"2025-12-17T03:49:41.648Z","updated_at":"2025-12-17T03:49:41.648Z"}
 */
struct GroupModel: Codable, Identifiable {
    let id: UUID
    let name: String
    let code: String
    let is_active: Bool
    let current_track_id: String? // Opcional porque puede ser null
    let current_time_ms: Int
    let is_playing: Bool
    let created_by: String?      // Opcional porque puede ser null
    let created_at: String       // Puedes usar Date si configuras un DateFormatter
    let updated_at: String
}
struct member: Codable {
    let id: String
    let name: String
    let role: String
    let user_id : String
    let joined_at: String
}


struct GroupReponseCreate: Codable {
    let status: Bool
    let group: GroupModel
    let members: [member]?
}


 
