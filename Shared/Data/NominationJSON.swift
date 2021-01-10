//
//  NominationJSON.swift
//  Potori
//
//  Created by Lucka on 4/1/2021.
//

import SwiftUI
import UniformTypeIdentifiers

struct LngLat: Codable {
    var lng: Double
    var lat: Double
}

struct NominationJSON: Codable {
    var id: String
    var title: String
    var image: String
    var scanner: Int16?
    
    var status: Int16
    var reasons: [Int16]?
    
    var confirmedTime: UInt64
    var confirmationMailId: String

    var resultTime: UInt64?
    var resultMailId: String?
    
    var lngLat: LngLat?
}

struct NominationJSONDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.json]
    
    var nominations: [NominationJSON]
    
    init(_ forNominations: [NominationJSON]) {
        nominations = forNominations
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        nominations = try decoder.decode([NominationJSON].self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(nominations)
        return .init(regularFileWithContents: data)
    }
}
