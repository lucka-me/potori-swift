//
//  NominationWidgetJSON.swift
//  Potori
//
//  Created by Lucka on 27/1/2021.
//

import Foundation

struct NominationWidgetJSON: Codable {
    
    #if os(macOS)
    static let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "labs.lucka.potori")!
        .appendingPathComponent("widget", isDirectory: true)
    #else
    static let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.labs.lucka.potori")!
        .appendingPathComponent("widget", isDirectory: true)
    #endif
    static let file = directory
        .appendingPathComponent("nomination.json")
    
    var id: String
    var title: String
    var image: String
    
    var status: Int16
    
    static func save(_ list: [NominationWidgetJSON]) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(list) else {
            return
        }
        if FileManager.default.fileExists(atPath: file.path) {
            try? data.write(to: file)
        } else {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            FileManager.default.createFile(atPath: file.path, contents: data, attributes: nil)
        }
    }
    
    static func load() -> [NominationWidgetJSON] {
        guard let data = try? Data(contentsOf: file) else {
            return []
        }
        let decoder = JSONDecoder()
        guard let list = try? decoder.decode([NominationWidgetJSON].self, from: data) else {
            return []
        }
        return list
    }
}
