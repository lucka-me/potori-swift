//
//  Nomination.swift
//  Potori
//
//  Created by Lucka on 28/12/2020.
//

import Foundation

class NominationRAW {
    
    var id: String = ""
    var title: String = ""
    var image: String = ""
    var scanner: StatusKit.ScannerCode = .unknown
    
    var status: StatusKit.StatusCode = .pending
    var reasons: [Int16] = []
    
    var confirmedTime: UInt64 = 0
    var confirmationMailId: String = ""
    var resultTime: UInt64 = 0
    var resultMailId: String = ""
    
    var lngLat: LngLat?
    
    init() { }
    
    init(_ forType: StatusKit.StatusCode, _ by: StatusKit.ScannerCode) {
        status = forType
        scanner = by
    }
    
    init(from: NominationJSON) {
        id = from.id
        title = from.title
        image = from.image
        
        if let solidScanner = from.scanner {
            scanner = StatusKit.ScannerCode(rawValue: solidScanner) ?? .unknown
        }
        
        if from.status == StatusKit.StatusCode.pending.rawValue {
            status = .pending
        } else if from.status == StatusKit.StatusCode.accepted.rawValue {
            status = .accepted
        } else {
            status = .rejected
            if let solidReasons = from.reasons {
                for code in solidReasons {
                    // Prevent add old codes and undeclared
                    guard
                        let reason = StatusKit.shared.reason[code]?.code,
                        reason != StatusKit.Reason.undeclared
                    else {
                        continue
                    }
                    if !reasons.contains(reason) {
                        reasons.append(reason)
                    }
                }
            } else {
                if
                    let reason = StatusKit.shared.reason[from.status]?.code,
                    reason != StatusKit.Reason.undeclared {
                    reasons.append(reason)
                }
            }
        }
        
        lngLat = from.lngLat
        
        confirmedTime = from.confirmedTime
        confirmationMailId = from.confirmationMailId

        resultTime = from.resultTime ?? 0
        resultMailId = from.resultMailId ?? ""
    }
    
    var json: NominationJSON {
        .init(
            id: id,
            title: title,
            image: image,
            scanner: scanner.rawValue,
            status: status.rawValue,
            reasons: reasons,
            confirmedTime: confirmedTime,
            confirmationMailId: confirmationMailId,
            resultTime: resultTime,
            resultMailId: resultMailId,
            lngLat: lngLat
        )
    }
    
    static func generateId(_ fromImage: String) -> String {
        return fromImage
            .replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
            .suffix(10)
            .lowercased()
    }
}
