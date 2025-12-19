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
struct AddTrackRequest : Encodable {
    let groupId : String
    let trackId : String
}


struct AddTrackResponse: Codable {
    let status: Bool
    let track : AudioTrack
}
 

/**
 "track": {
         "id": "eeec4efe-16c9-4a41-a53b-b7e8ff9f9e92",
         "title": "CHYSTEMC - EARLY Videoclip.mp3",
         "artist": "CHYSTEMC - EARLY Videoclip.mp3",
         "file_url": "https://go2storage.s3.us-east-2.amazonaws.com/audio/73c02a83-8907-4d6e-82e3-4b0ae8269949.mp3",
         "duration_ms": 227448,
         "added_by": "02e0fcfe-2e1b-41f8-a4de-726708e68ddc",
         "uploaded_by": "02e0fcfe-2e1b-41f8-a4de-726708e68ddc",
         "created_at": "2025-12-18T04:12:51.707Z"
     }
 
 */


struct AddMemberRequest : Encodable {
    let groupId : String
    let role : String = "member"
    let email : String
}
/*
 {
     "status": false,
     "msg": "Member already in group"
 }
 }
 *
 */
// 1. Respuesta principal
struct AddMemberResponse: Codable {
    let status: Bool
    let msg : String?
    let member: Member?
}
// 2. Modelo del Miembro (Member)
struct Member: Codable {
    let id: String
    let groupID: String
    let userID: String
    let guestName: String? // Opcional porque es null en tu ejemplo
    let role: String
    let joinedAt: String
    let user: UserAddMember
    let group: GroupAddmember

    enum CodingKeys: String, CodingKey {
        case id
        case groupID = "group_id"
        case userID = "user_id"
        case guestName = "guest_name"
        case role
        case joinedAt = "joined_at"
        case user, group
    }
}
// 3. Modelo del Usuario (User)
struct UserAddMember: Codable {
    let id: String
    let username: String?
    let name: String
    let password: String
    let email: String
    let avatarURL: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, username, name, password, email
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// 4. Modelo del Grupo (Group)
struct GroupAddmember: Codable {
    let id: String
    let name: String
    let code: String
    let isActive: Bool
    let currentTrackID: String?
    let currentTimeMS: Int
    let isPlaying: Bool
    let createdBy: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, code
        case isActive = "is_active"
        case currentTrackID = "current_track_id"
        case currentTimeMS = "current_time_ms"
        case isPlaying = "is_playing"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
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
    // Estos campos solo vienen en la lista, no en create
    let created_by_name: String?
    let created_by_avatar_url: String?
}


struct GroupReponseCreate: Codable {
    let status: Bool
    let group: GroupModel
    let member: [MemberCreate]?  // Es "member" no "members" en el JSON
}

// Response for joining a group by code
struct JoinGroupResponse: Codable {
    let status: Bool
    let msg: String?
    let group: GroupModel?
}

// Estructura para el member en la respuesta de crear grupo
struct MemberCreate: Codable {
    let id: String
    let group_id: String
    let user_id: String
    let guest_name: String?
    let role: String
    let joined_at: String
}

//struct GroupMember: Identifiable {
//    let id: String
//    let name: String
//    let role: MemberRole
//}

enum MemberRole: String, Decodable {
    case dj
    case member

}

struct GroupTrack: Decodable {
    let id: String
    let title: String
    let artist: String
    let fileURL: URL
    let durationMs: Int
    let position: Int
    let addedBy: String

    enum CodingKeys: String, CodingKey {
        case id, title, artist, position
        case fileURL = "file_url"
        case durationMs = "duration_ms"
        case addedBy = "added_by"
    }
}
 struct GroupMember: Decodable, Identifiable {
    let id: String
    let name: String
    let email: String
    let role: MemberRole
    let avatarURL: URL?

    enum CodingKeys: String, CodingKey {
        case id, name, email, role
        case avatarURL = "avatar_url"
    }
}

struct GroupResponseDetail: Decodable {
    let status: Bool
    let group: GroupDetail
}
struct GroupDetail: Decodable {
    let id: String
    let name: String
    let code: String
    var isPlaying: Bool
    var currentTimeMs: Int
    var members: [GroupMember]
    let currentTrack: GroupTrack?

    enum CodingKeys: String, CodingKey {
        case id, name, code, members
        case isPlaying = "is_playing"
        case currentTimeMs = "current_time_ms"
        case currentTrack = "current_track"
    }
}

 
