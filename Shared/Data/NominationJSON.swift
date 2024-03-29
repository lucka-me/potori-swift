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
    
    struct Document: FileDocument {
        static var readableContentTypes: [ UTType ] = [ .json ]
        
        private var nominations: [ NominationJSON ]
        
        init(for nominations: [ NominationJSON ]) {
            self.nominations = nominations
        }
        
        init(configuration: ReadConfiguration) throws {
            guard let data = configuration.file.regularFileContents else {
                throw CocoaError(.fileReadCorruptFile)
            }
            let decoder = JSONDecoder()
            nominations = try decoder.decode([ NominationJSON ].self, from: data)
        }
        
        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(nominations)
            return .init(regularFileWithContents: data)
        }
    }
    
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
