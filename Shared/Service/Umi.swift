//
//  NominationStatus.swift
//  Potori
//
//  Created by Lucka on 28/12/2020.
//

import SwiftUI

final class Umi {
    
    // Scanner
    class Scanner {
        
        enum Code: Int16 {
            case unknown    = 0
            case redacted   = 1
            case prime      = 2
            case go         = 3
        }
        
        fileprivate struct JSON: Codable {
            let code: Int16
            let title: String
        }
        
        let code: Code
        let title: LocalizedStringKey
        
        fileprivate init(_ from: JSON) {
            code = Code(rawValue: from.code)!
            title = LocalizedStringKey(from.title)
        }
        
        var predicate: NSPredicate {
            .init(format: "scanner = %d", code.rawValue)
        }
    }
    
    // Status
    class Status: Identifiable {
        
        enum Code: Int16 {
            case pending = 0
            case accepted = 1
            case rejected = 101
        }
        
        class Query {
            
            fileprivate struct JSON: Codable {
                let scanner: Int16
                let query: String
            }
            
            let scanner: Scanner.Code
            let query: String
            
            fileprivate init(_ from: JSON) {
                scanner = Scanner.Code(rawValue: from.scanner)!
                query = from.query
            }
        }
        
        fileprivate struct JSON: Codable {
            let code: Int16
            let title: String
            let iconSF: String
            
            let queries: [Query.JSON]
        }
        
        let code: Code
        
        let title: LocalizedStringKey
        let icon: String
        let color: Color

        let queries: [Scanner.Code : Query]
        
        fileprivate init(_ from: JSON) {
            
            code = Code(rawValue: from.code)!
            
            title = LocalizedStringKey(from.title)
            icon = from.iconSF
            switch code {
                case .pending: color = .orange
                case .accepted: color = .green
                case .rejected: color = .red
            }
            
            var queries: [Scanner.Code : Query] = [:]
            for queryJSON in from.queries {
                let query = Query(queryJSON)
                queries[query.scanner] = query
            }
            self.queries = queries
        }
        
        var predicate: NSPredicate { .init(format: "status = %d", code.rawValue) }
    }
    
    // Reason
    class Reason: Equatable, Identifiable {
        
        typealias Code = Int16
        
        class Keywords {
            
            fileprivate struct JSON: Codable {
                let scanner: Int16
                let keywords: [String]
            }
            
            let scanner: Scanner.Code
            let keywords: [String]
            
            fileprivate init(_ from: JSON) {
                scanner = Scanner.Code(rawValue: from.scanner)!
                keywords = from.keywords
            }
        }
        
        fileprivate struct JSON: Codable {
            let code: Int16
            let title: String
            let iconSF: String
            
            let keywords: [Reason.Keywords.JSON]
        }
        
        static let undeclared: Code = 101
        
        let code: Code
        
        let title: LocalizedStringKey
        let icon: String
        
        let keywords: [Scanner.Code : Reason.Keywords]
        
        fileprivate init(_ from: JSON) {
            title = LocalizedStringKey(from.title)
            icon = from.iconSF

            code = from.code
            var keywords: [Scanner.Code : Reason.Keywords] = [:]
            for keywordsJSON in from.keywords {
                let reasonKeywords = Reason.Keywords(keywordsJSON)
                keywords[reasonKeywords.scanner] = reasonKeywords
            }
            self.keywords = keywords
        }
        
        static func == (lhs: Reason, rhs: Reason) -> Bool {
            lhs.code == rhs.code
        }
        
        var predicate: NSPredicate {
            if code == Self.undeclared {
                return .init(format: "status = %d AND reasons.@count = 0", Status.Code.rejected.rawValue)
            } else {
                return .init(format: "status = %d AND ANY reasons.code = %d", Status.Code.rejected.rawValue, code)
            }
        }
        
        static var hasNominationsPredicate: NSPredicate {
            .init(format: "nominations.@count > 0")
        }
    }
    
    fileprivate struct DataJSON: Codable {
        let version: String
        let scanners: [Scanner.JSON]
        let statuses: [Status.JSON]
        let reasons: [Reason.JSON]
    }
    
    static let shared = Umi()
    #if DEBUG
    static let unitTestShared = Umi(forUnitTest: true)
    #endif
    
    let version: String
    
    let scanner: [Scanner.Code: Scanner]
    let status: [Status.Code: Status]
    let reason: [Reason.Code: Reason]
    
    /// Scanner list sorted by code
    let scannerAll: [Scanner]
    /// Status list sorted by code
    let statusAll: [Status]
    /// Reason list sorted by code
    let reasonAll: [Reason]
    
    private init(forUnitTest: Bool = false) {
        
        #if DEBUG
        let bundle = forUnitTest ? Bundle(for: type(of: self)) : Bundle.main
        #else
        let bundle = Bundle.main
        #endif
        let url = bundle.url(forResource: "umi", withExtension: "json")!
        let data = (try? Data(contentsOf: url))!
        let decoder = JSONDecoder()
        let dataJSON = (try? decoder.decode(DataJSON.self, from: data))!
        
        version = dataJSON.version
        
        scanner = dataJSON.scanners.reduce(into: [:]) { dict, value in
            let scanner = Scanner(value)
            dict[scanner.code] = scanner
        }
        status = dataJSON.statuses.reduce(into: [:]) { dict, value in
            let type = Status(value)
            dict[type.code] = type
        }
        reason = dataJSON.reasons.reduce(into: [:]) { dict, value in
            let reason = Reason(value)
            dict[reason.code] = reason
        }
        scannerAll = scanner
            .filter { $0.key != .unknown }
            .sorted { a, b in a.key.rawValue < b.key.rawValue }
            .map { $0.value }
        statusAll = status
            .sorted { a, b in a.key.rawValue < b.key.rawValue }
            .map { $0.value }
        reasonAll = reason
            .sorted { a, b in a.key < b.key }
            .map { $0.value }
    }
    
    #if DEBUG
    static func unitTestInit() -> Umi {
        Umi.init(forUnitTest: true)
    }
    #endif
}
