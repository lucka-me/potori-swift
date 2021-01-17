//
//  FilterManager.swift
//  Potori
//
//  Created by Lucka on 17/1/2021.
//

import Foundation

class FilterManager: ObservableObject {
    
    typealias StatusDictionary = [Umi.Status.Code : Status]
    
    class Status: ObservableObject {
        let code: Umi.Status.Code
        @Published var isOn = true
        
        init(_ code: Umi.Status.Code) {
            self.code = code
        }
    }

    @Published var status: StatusDictionary = [:]
    
    init() {
        for code in Umi.shared.status.keys {
            status[code] = Status(code)
        }
    }
    
    var predicate: NSPredicate {
        .init(format: "status IN %@", status.filter { $0.value.isOn }.map { $0.key.rawValue })
    }
}
