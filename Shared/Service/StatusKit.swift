//
//  NominationStatus.swift
//  Potori
//
//  Created by Lucka on 28/12/2020.
//

import SwiftUI

final class StatusKit {
    
    // Enums
    enum StatusCode: Int16 {
        case pending = 0
        case accepted = 1
        case rejected = 101
    }

    enum ScannerCode: Int16 {
        case unknown = 0
        case redacted = 1
        case prime = 2
    }
    
    // Scanner
    fileprivate struct ScannerJSON: Codable {
        let code: Int16
        let title: String
    }

    struct Scanner {
        let code: ScannerCode
        let title: String
        
        fileprivate init(_ from: ScannerJSON) {
            code = ScannerCode(rawValue: from.code)!
            title = from.title
        }
    }
    
    // Status
    fileprivate struct MailQueryJSON: Codable {
        let scanner: Int16
        let query: String
    }

    class MailQuery {
        let scanner: ScannerCode
        let query: String
        
        fileprivate init(_ from: MailQueryJSON) {
            scanner = ScannerCode(rawValue: from.scanner)!
            query = from.query
        }
    }

    fileprivate struct StatusJSON: Codable {
        let key: String
        let code: Int16
        let title: String
        let icon: String
        let color: String
        
        let queries: [MailQueryJSON]
    }

    class Status {
        let title: LocalizedStringKey
        let icon: String
        let color: String

        let code: StatusCode

        let queries: [ScannerCode : MailQuery]
        
        fileprivate init(_ from: StatusJSON) {
            title = LocalizedStringKey(from.title)
            icon = from.icon
            color = from.color

            code = StatusCode(rawValue: from.code)!
            var queries: [ScannerCode : MailQuery] = [:]
            for queryJSON in from.queries {
                let query = MailQuery(queryJSON)
                queries[query.scanner] = query
            }
            self.queries = queries
        }
    }
    
    // Reason
    fileprivate struct ReasonKeywordsJSON: Codable {
        let scanner: Int16
        let keywords: [String]
    }

    class ReasonKeywords {
        let scanner: ScannerCode
        let keywords: [String]
        
        fileprivate init(_ from: ReasonKeywordsJSON) {
            scanner = ScannerCode(rawValue: from.scanner)!
            keywords = from.keywords
        }
    }
    
    fileprivate struct ReasonJSON: Codable {
        let key: String
        let code: Int16
        let oldCode: Int16?
        let title: String
        let icon: String
        let color: String
        
        let keywords: [ReasonKeywordsJSON]
    }
    
    class Reason: Equatable {
        
        static let undeclared: Int16 = 101
        
        let title: LocalizedStringKey
        let icon: String
        let color: String
        
        let code: Int16
        let keywords: [ScannerCode : ReasonKeywords]
        
        fileprivate init(_ from: ReasonJSON) {
            title = LocalizedStringKey(from.title)
            icon = from.icon
            color = from.color

            code = from.code
            var keywords: [ScannerCode : ReasonKeywords] = [:]
            for keywordsJSON in from.keywords {
                let reasonKeywords = ReasonKeywords(keywordsJSON)
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
        let scanners: [ScannerJSON]
        let types: [StatusJSON]
        let reasons: [ReasonJSON]
    }
    
    static let shared = StatusKit()
    
    let version: String
    
    let scanner: [ScannerCode: Scanner]
    let status: [StatusCode: Status]
    let reason: [Int16: Reason]
    
    let statusAll: [Status]
    
    private init() {
        
        let file = Bundle.main.url(forResource: "status.json", withExtension: nil)!
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
