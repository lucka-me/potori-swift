//
//  Brainstorming.swift
//  Potori
//
//  Created by Lucka on 24/5/2021.
//

import Foundation

class Brainstorming {
    
    struct Record: Decodable {
        let lat: Double
        let lng: Double
    }
    
    static let shared = Brainstorming()
    
    private static let epoch = Date(timeIntervalSince1970: 1518796800)
    
    private init() { }
    
    func query(_ id: String) async -> Record? {
        let data = await URLSession.shared.dataTask(with: "https://oprbrainstorming.firebaseio.com/c/reviews/\(id).json")
        guard let solidData = data else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(Record.self, from: solidData)
    }
    
    static func isBeforeEpoch(when resultTime: Date, status: Umi.Status.Code) -> Bool {
        status != .pending && resultTime < Self.epoch
    }
}
