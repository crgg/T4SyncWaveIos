//
//  UserDefaults+Extensions.swift
//  t4ever
//
//  Created by Ramon Gajardo on 12/12/25.
//

import Foundation



extension UserDefaults {
    enum Keys : String {
        case userID
        case name
        case phone
        case isPrivacy
        case isLoggedIn
        case tokenDevice
        case intervalPosition
        case loginTrip
        case longitude
        case latitude
        case customer_name
        case customer_id
        case share_location
        case current_load_number
        case current_url_avatar
        case customer_type
        case djMuted

    }
    
    func setLoggedIn(_ value: Bool) {
        set(value, forKey: Keys.isLoggedIn.rawValue)
        synchronize()
        
    }
    
    func isLoggedIn()-> Bool {
        return bool(forKey: Keys.isLoggedIn.rawValue)
    }

    // DJ Mute state persistence
    func setDJMuted(_ value: Bool) {
        set(value, forKey: Keys.djMuted.rawValue)
        synchronize()
    }

    func isDJMuted() -> Bool {
        return bool(forKey: Keys.djMuted.rawValue)
    }
}
