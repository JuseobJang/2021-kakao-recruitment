//
//  Response.swift
//  kakaoTest
//
//  Created by seob_jj on 2021/11/12.
//

import Foundation

struct Start: Codable {
    let auth_key: String
    let problem: Int
    let time: Int
}

struct TruckResponse: Codable {
    let trucks: [Truck]
}

struct Truck: Codable {
    let id: Int
    let location_id: Int
    let loaded_bikes_count: Int
}

struct LocationResponse: Codable {
    let locations: [Location]
}

struct Location: Codable {
    let id: Int
    let located_bikes_count: Int
}

struct Command: Codable {
    let truck_id: Int
    let command: [Int]
}

struct Simulate: Codable {
    let status: String
    let time: Int
//    let failed_requests_count: Int
    let distance: String
}

struct Score: Codable {
    let score: Float
}


