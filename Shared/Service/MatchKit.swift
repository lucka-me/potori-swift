//
//  MatchManager.swift
//  Potori
//
//  Created by Lucka on 16/1/2021.
//

import Foundation

final class MatchKit: ObservableObject {
    
    typealias OnProgressCallback = (Double) -> Void
    typealias FinishCallback = ([NominationRAW]) -> Void
    
    class Pack {
        let target: NominationRAW
        var candidates: [NominationRAW] = []
        
        init(_ forTarget: NominationRAW) {
            self.target = forTarget
        }
    }
    
    private let progress = Progress()
    
    private var queue: [Pack] = []
    private var matched: [NominationRAW] = []
    
    @Published var pack: Pack? = nil
    
    func start(
        _ forTargets: [NominationRAW],
        _ candidates: [NominationRAW],
        _ callback: @escaping FinishCallback
    ) {
        queue = forTargets
            .map { target in
                let pack = Pack(target)
                let checkScanner = target.scanner != .unknown
                pack.candidates = candidates.filter { candidate in
                    target.title == candidate.title
                        && target.resultTime > candidate.confirmedTime
                        && (!checkScanner || candidate.scanner == .unknown || target.scanner == candidate.scanner)
                }
                return pack
            }
            .filter { !$0.candidates.isEmpty }
        if queue.isEmpty {
            callback([])
            return
        }
        progress.start(queue.count)
        progress.onFinished = {
            self.pack = nil
            callback(self.matched)
        }
        matched = []
        pack = self.queue.removeFirst()
    }
    
    func match(_ inPack: Pack, _ at: Int?) {
        if let index = at, index < inPack.candidates.count {
            let target = inPack.target
            let candidate = inPack.candidates[index]
            target.id = candidate.id
            target.image = candidate.image
            if target.merge(candidate) {
                matched.append(target)
            }
        }
        if progress.finishItem() {
            pack = self.queue.removeFirst()
        }
    }
    
    func onProgress(_ onProgress: @escaping OnProgressCallback) {
        self.progress.onProgress = onProgress
    }
    
    #if DEBUG
    static var preview: Pack {
        let nominations = Dia.preview.nominations
        let pack = Pack(nominations[0].toRaw())
        pack.candidates = nominations.map { $0.toRaw() }
        return pack
    }
    #endif
}

fileprivate class Progress {
    
    var onProgress: MatchKit.OnProgressCallback = { _ in }
    var onFinished: () -> Void = { }
    
    private var total = 0
    private var finished = 0
    
    func start(_ forTotal: Int) {
        total = forTotal
        finished = 0
    }
    
    /// Finish one item
    /// - Returns: Should continue or not
    func finishItem() -> Bool {
        finished += 1
        onProgress(percent)
        if !left {
            onFinished()
            return false
        }
        return true
    }
    
    private var left: Bool { finished < total }
    
    private var percent: Double { total == 0 ? 0.0 : Double(finished) / Double(total) }
}
