//
//  ProgressInspector.swift
//  Potori
//
//  Created by Lucka on 19/5/2021.
//

import Foundation

class ProgressInspector: ObservableObject {
    
    static let shared = ProgressInspector()
    
    @Published var total: Int = 0
    @Published var done: Int = 0
    
    private init() {
        
    }
    
    func set(done: Int, total: Int) {
        DispatchQueue.main.async {
            self.total = total
            self.done = done
        }
    }
    
    func set(done: Int) {
        DispatchQueue.main.async {
            self.done = done
        }
    }
    
    func set(total: Int) {
        DispatchQueue.main.async {
            self.total = total
        }
    }
    
    func clear() {
        set(done: 0, total: 0)
    }
}
