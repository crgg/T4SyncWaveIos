//
//  NotificationName+Extensions.swift
//  t4ever
//
//  Created by Ramon Gajardo on 12/12/25.
//

import Foundation
extension Notification.Name {
    // Cuando el AppCore detecta un 401, postea esta notificación.
    static let userSessionExpired = Notification.Name("userSessionExpired")
    
    // Cuando la música termina de reproducirse (sin repeat)
    static let audioDidFinishPlaying = Notification.Name("audioDidFinishPlaying")
}

