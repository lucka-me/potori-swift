//
//  FilterManager.swift
//  Potori
//
//  Created by Lucka on 17/1/2021.
//

import Foundation

class FilterManager: ObservableObject {
    
    typealias StatusDictionary = [Umi.Status.Code : Status]
    typealias ReasonDictionary = [Umi.Reason.Code : Reason]
    
    class Status: ObservableObject {
        let code: Umi.Status.Code
        @Published var isOn = true
        
        init(_ code: Umi.Status.Code) {
            self.code = code
        }
    }
    
    class Reason: ObservableObject {
        let code: Umi.Reason.Code
        @Published var isOn = true
        
        init(_ code: Umi.Reason.Code) {
            self.code = code
        }
    }

    @Published var status: StatusDictionary = [:]
    @Published var reason: ReasonDictionary = [:]
    
    init() {
        for code in Umi.shared.status.keys {
            status[code] = Status(code)
        }
        for code in Umi.shared.reason.keys {
            reason[code] = Reason(code)
        }
    }
    
    var predicate: NSPredicate {
        .init(format: "status IN %@", status.filter { $0.value.isOn }.map { $0.key.rawValue })
    }
    
    func filterByReason(_ inList: [Nomination]) -> [Nomination] {
        if allReasonsEnabled {
            return inList
        }
        if allReasonsDisabled {
            return inList.filter { $0.status != Umi.Status.Code.rejected.rawValue }
        }
        let enabled = enabledReasons
        let enabledUndeclared = enabledReasons.contains(Umi.Reason.undeclared)
        return inList.filter { nomination in
            if nomination.status != Umi.Status.Code.rejected.rawValue {
                return true
            }
            if nomination.reasons.isEmpty {
                return enabledUndeclared
            }
            for code in nomination.reasons {
                if enabled.contains(code) {
                    return true
                }
            }
            return false
        }
    }
    
    private var enabledReasons: [Umi.Reason.Code] {
        reason.filter { $0.value.isOn }.map { $0.key }
    }
    
    private var allReasonsEnabled: Bool {
        reason.allSatisfy { $0.value.isOn }
    }
    
    private var allReasonsDisabled: Bool {
        reason.allSatisfy { !$0.value.isOn }
    }
}
