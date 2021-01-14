//
//  NominationStatus.swift
//  Potori
//
//  Created by Lucka on 28/12/2020.
//

import SwiftUI

final class Umi {
    
    // Scanner
    struct Scanner {
        
        enum Code: Int16 {
            case unknown = 0
            case redacted = 1
            case prime = 2
        }
        
        fileprivate struct JSON: Codable {
            let code: Int16
            let title: String
        }
        
        let code: Code
        let title: String
        
        fileprivate init(_ from: JSON) {
            code = Code(rawValue: from.code)!
            title = from.title
        }
    }
    
    // Status
    class Status {
        
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
            let key: String
            let code: Int16
            let title: String
            let icon: String
            let color: String
            
            let queries: [Query.JSON]
        }
        
        let title: LocalizedStringKey
        let icon: String
        let color: Color

        let code: Code

        let queries: [Scanner.Code : Query]
        
        fileprivate init(_ from: JSON) {
            title = LocalizedStringKey(from.title)
            icon = from.icon
            color = Color(from.color)

            code = Code(rawValue: from.code)!
            var queries: [Scanner.Code : Query] = [:]
            for queryJSON in from.queries {
                let query = Query(queryJSON)
                queries[query.scanner] = query
            }
            self.queries = queries
        }
    }
    
    // Reason
    class Reason: Equatable {
        
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
            let key: String
            let code: Int16
            let oldCode: Int16?
            let title: String
            let icon: String
            let color: String
            
            let keywords: [Reason.Keywords.JSON]
        }
        
        static let undeclared: Code = 101
        
        let title: LocalizedStringKey
        let icon: String
        let color: String
        
        let code: Code
        let keywords: [Scanner.Code : Reason.Keywords]
        
        fileprivate init(_ from: JSON) {
            title = LocalizedStringKey(from.title)
            icon = from.icon
            color = from.color

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
    }
    
    fileprivate struct DataJSON: Codable {
        let version: String
        let scanners: [Scanner.JSON]
        let types: [Status.JSON]
        let reasons: [Reason.JSON]
    }
    
    static let shared = Umi()
    
    let version: String
    
    let scanner: [Scanner.Code: Scanner]
    let status: [Status.Code: Status]
    let reason: [Int16: Reason]
    
    let statusAll: [Status]
    
    private init() {
        
        let file = Bundle.main.url(forResource: "umi.json", withExtension: nil)!
        let data = (try? Data(contentsOf: file))!
        let decoder = JSONDecoder()
        let dataJSON = (try? decoder.decode(DataJSON.self, from: data))!
        
        version = dataJSON.version
        
        scanner = dataJSON.scanners.reduce(into: [:]) { dict, value in
            let scanner = Scanner(value)
            dict[scanner.code] = scanner
        }
        status = dataJSON.types.reduce(into: [:]) { dict, value in
            let type = Status(value)
            dict[type.code] = type
        }
        reason = dataJSON.reasons.reduce(into: [:]) { dict, value in
            let reason = Reason(value)
            dict[reason.code] = reason
            if let solidOldCode = value.oldCode {
                dict[solidOldCode] = reason
            }
        }
        statusAll = [
            status[.pending]!,
            status[.accepted]!,
            status[.rejected]!
        ]
    }
}
