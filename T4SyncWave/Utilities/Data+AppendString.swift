//
//  Data+AppendString.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

import Foundation

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

