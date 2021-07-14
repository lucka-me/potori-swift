//
//  ModelData.swift
//  Potori
//
//  Created by Lucka on 29/12/2020.
//

import Foundation

#if os(iOS)
import BackgroundTasks
import UserNotifications
#endif

final class Service: ObservableObject {
    
    typealias RefreshCompletionHandler = (Status, Int) -> Void
    typealias ImportCompletionHandler = (Int) -> Void
    
    enum Status {
        case idle
        case syncing
        case processingMails
        case requestMatch
        case queryingBrainstorming
    }
    
    class MatchPack: ObservableObject {
        let target: NominationRAW
        var candidates: [NominationRAW] = []
        @Published var selected: String = ""
        
        init(_ target: NominationRAW) {
            self.target = target
        }
        
        #if DEBUG
        static func preview(_ index: Int) -> MatchPack {
            let nominations = Dia.preview.nominations().sorted { $0.title < $1.title }
            let pack = MatchPack(nominations[index].raw)
            pack.candidates = nominations.map { $0.raw }
            return pack
        }
        #endif
    }
    
    class MatchData {
        var packs: [MatchPack] = []
        var callback: () -> Void = { }
    }
    
    private enum NominationFile: String {
        case standard = "nominations.json"
        case legacy = "potori.json"
    }
    
    static let shared = Service()
    
    #if os(iOS)
    private static let refreshTaskID = "dev.lucka.Potori.refresh"
    #endif
    
    @Published var status: Status = .idle
    
    let matchData = MatchData()
    
    private var refreshCompletionHandler: RefreshCompletionHandler = { _, _ in }
    
    private init() { }
    
    /// Migrate data from potori.json
    func migrateFromGoogleDrive(_ completionHandler: @escaping ImportCompletionHandler) {
        download(.legacy) { count in
            completionHandler(count)
            self.set(status: .idle)
        }
    }
    
    @discardableResult
    func refresh(completionHandler: @escaping RefreshCompletionHandler = { _, _ in }) -> Bool {
        if status != .idle || !GoogleKit.Auth.shared.authorized {
            return false
        }
        refreshCompletionHandler = { status, count in
            self.refreshCompletionHandler = { _, _ in }
            completionHandler(status, count)
        }
        if UserDefaults.Google.sync {
            download { _ in
                self.processMails()
            }
        } else {
            processMails()
        }
        return true
    }
    
    func sync(performDownload: Bool = true, performUpload: Bool = true) {
        if !performDownload && !performUpload {
            return
        }
        if performDownload {
            download { _ in
                if performUpload {
                    self.upload { self.set(status: .idle) }
                } else {
                    self.set(status: .idle)
                }
            }
        } else {
            upload { self.set(status: .idle) }
        }
    }
    
    private func download(_ file: NominationFile = .standard, completionHandler: @escaping ImportCompletionHandler) {
        set(status: .syncing)
        async {
            var saved = 0
            if let jsons: [ NominationJSON ] = try? await GoogleKit.Drive.shared.download(file.rawValue) {
                let raws = jsons.map { NominationRAW(from: $0) }
                saved = Dia.shared.save(raws, merge: true)
            }
            completionHandler(saved)
        }
    }
    
    func upload(_ completionHandler: @escaping () -> Void) {
        set(status: .syncing)
        let nominations = Dia.shared.nominations()
        let raws = nominations.map { $0.raw }
        let jsons = raws.map { $0.json }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(jsons) {
            async {
                try? await GoogleKit.Drive.shared.upload(
                    data, to: NominationFile.standard.rawValue, of: "application/json"
                )
                completionHandler()
            }
        }
    }
    
    private func set(status: Status) {
        DispatchQueue.main.async {
            self.status = status
        }
    }
    
    private func processMails() {
        let nominations = Dia.shared.nominations()
        let raws = nominations.map { $0.raw }
        set(status: .processingMails)
        let started = Mari.shared.start(with: raws) { nominations in
            self.arrange(nominations)
        }
        if !started {
            set(status: .idle)
            refreshCompletionHandler(status, 0)
        }
    }
    
    private func arrange(_ raws: [ NominationRAW ]) {
        var reduced: [NominationRAW] = []
        var matchTargets: [NominationRAW] = []
        reduced.reserveCapacity(raws.capacity)
        var mergeCount = 0
        reduced = raws.reduce(into: reduced) { list, raw in
            if raw.id.isEmpty {
                matchTargets.append(raw)
                return
            }
            // Merge
            var merged = false
            for target in list {
                if target.merge(raw) {
                    merged = true
                    mergeCount += 1
                    break
                }
            }
            if !merged {
                list.append(raw)
            }
        }
        match(matchTargets, from: reduced, merged: mergeCount)
    }
    
    private func match(_ targets: [NominationRAW], from list: [NominationRAW], merged: Int) {
        if targets.isEmpty {
            queryBrainstorming(list, merged: merged)
            return
        }
        refreshCompletionHandler(status, 0)
        let pendings = list.filter { $0.status == .pending }
        let packs: [MatchPack] = targets
            .map { target in
                let pack = MatchPack(target)
                let checkScanner = target.scanner != .unknown
                pack.candidates = pendings.filter { candidate in
                    target.title == candidate.title
                        && target.resultTime > candidate.confirmedTime
                        && (!checkScanner || candidate.scanner == .unknown || target.scanner == candidate.scanner)
                }
                return pack
            }
            .filter { !$0.candidates.isEmpty }
        if packs.isEmpty {
            queryBrainstorming(list, merged: merged)
            return
        }
        matchData.packs = packs
        matchData.callback = {
            self.matchData.callback = { }
            for pack in self.matchData.packs {
                if pack.selected.isEmpty {
                    continue
                }
                guard let selected = pack.candidates.first(where: { $0.id == pack.selected }) else {
                    continue
                }
                pack.target.id = selected.id
                pack.target.image = selected.image
                for nomination in list {
                    if nomination.merge(pack.target) {
                        break
                    }
                }
            }
            self.matchData.packs = []
            self.queryBrainstorming(list, merged: merged)
        }
        set(status: .requestMatch)
    }
    
    private func queryBrainstorming(_ raws: [ NominationRAW ], merged: Int) {
        if !UserDefaults.Brainstorming.query {
            saveAndSync(raws, merged: merged)
            return
        }
        let list = raws.filter { $0.lngLat == nil }
        if list.isEmpty {
            saveAndSync(raws, merged: merged)
            return
        }
        ProgressInspector.shared.set(done: 0, total: list.count)
        set(status: .queryingBrainstorming)
        async {
            await withTaskGroup(of: Void.self) { taskGroup in
                for raw in list {
                    taskGroup.async {
                        await self.queryBrainstorming(raw)
                    }
                }
            }
            saveAndSync(raws, merged: merged)
        }
    }
    
    private func queryBrainstorming(_ raw: NominationRAW) async {
        let record = try? await Brainstorming.shared.query(raw.id)
        if let solidRecord = record {
            raw.lngLat = .init(lng: solidRecord.lng, lat: solidRecord.lat)
        }
        ProgressInspector.shared.step()
    }
    
    private func saveAndSync(_ raws: [NominationRAW], merged: Int) {
        let updateCount = Dia.shared.save(raws) + merged
        if UserDefaults.Google.sync {
            upload {
                self.set(status: .idle)
                self.refreshCompletionHandler(self.status, updateCount)
            }
        } else {
            set(status: .idle)
            refreshCompletionHandler(status, updateCount)
        }
    }
    
    #if DEBUG
    static let preview: Service = {
        let forPreview = Service()
        forPreview.matchData.packs = [
            MatchPack.preview(0),
            MatchPack.preview(1)
        ]
        return forPreview
    }()
    #endif
}
