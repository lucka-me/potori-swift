//
//  Brainstorming.swift
//  Potori
//
//  Created by Lucka on 24/5/2021.
//

import Foundation

class Brainstorming {
    
    enum ErrorType: Error {
        case invalidID
        case notFound
        case unableToDecode
    }
    
    struct Record: Decodable {
        let lat: Double
        let lng: Double
    }
    
    static let shared = Brainstorming()
    
    private static let epoch = Date(timeIntervalSince1970: 1518796800)
    
    private init() { }
    
    func query(_ id: String) async throws -> Record {
        guard let url = URL(string: "https://oprbrainstorming.firebaseio.com/c/reviews/\(id).json") else {
            throw ErrorType.invalidID
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        let record: Record
        do {
            record = try decoder.decode(Record.self, from: data)
        } catch DecodingError.valueNotFound(_, _) {
            throw ErrorType.notFound
        } catch {
            throw ErrorType.unableToDecode
        }
        return record
    }
    
    static func isBeforeEpoch(when resultTime: Date, status: Umi.Status.Code) -> Bool {
        status != .pending && resultTime < Self.epoch
    }
}
