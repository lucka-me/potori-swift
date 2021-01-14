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
    var scanner: Umi.Scanner.Code = .unknown
    
    var status: Umi.Status.Code = .pending
    var reasons: [Int16] = []
    
    var confirmedTime: UInt64 = 0
    var confirmationMailId: String = ""
    var resultTime: UInt64 = 0
    var resultMailId: String = ""
    
    var lngLat: LngLat?
    
    init() { }
    
    init(_ forType: Umi.Status.Code, _ by: Umi.Scanner.Code) {
        status = forType
        scanner = by
    }
    
    init(from: NominationJSON) {
        id = from.id
        title = from.title
        image = from.image
        
        if let solidScanner = from.scanner {
            scanner = Umi.Scanner.Code(rawValue: solidScanner) ?? .unknown
        }
        
        if from.status == Umi.Status.Code.pending.rawValue {
            status = .pending
        } else if from.status == Umi.Status.Code.accepted.rawValue {
            status = .accepted
        } else {
            status = .rejected
            if let solidReasons = from.reasons {
                for code in solidReasons {
                    // Prevent add old codes and undeclared
                    guard
                        let reason = Umi.shared.reason[code]?.code,
                        reason != Umi.Reason.undeclared
                    else {
                        continue
                    }
                    if !reasons.contains(reason) {
                        reasons.append(reason)
                    }
                }
            } else {
                if
                    let reason = Umi.shared.reason[from.status]?.code,
                    reason != Umi.Reason.undeclared {
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
        fromImage
            .replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
            .suffix(10)
            .lowercased()
    }
    
    static func generateImageURL(_ fromImage: String) -> String {
        "https://lh3.googleusercontent.com/\(fromImage)"
    }
}
