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
    
    @Published var status: Status = .idle
    
    let matchData = MatchData()
    
    private var refreshCompletionHandler: RefreshCompletionHandler = { _, _ in }
    
    private init() { }
    
    /// Migrate data from potori.json
    func migrateFromGoogleDrive(_ completionHandler: @escaping ImportCompletionHandler) {
        async {
            let count = try? await download(.legacy)
            update(status: .idle)
            completionHandler(count ?? 0)
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
        async {
            if UserDefaults.Google.sync {
                let _ = try? await download()
            }
            processMails()
        }
        return true
    }
    
    func sync(performDownload: Bool = true, performUpload: Bool = true) async throws -> Int {
        var count = 0
        if performUpload {
            count = try await download()
        }
        if performUpload {
            try await upload()
        }
        update(status: .idle)
        return count
    }
    
    @discardableResult
    private func download(_ file: NominationFile = .standard) async throws -> Int {
        update(status: .syncing)
        guard
            let jsons: [ NominationJSON ] = try await GoogleKit.Drive.shared.download(file.rawValue)
        else {
            return 0
        }
        let raws = jsons.map { NominationRAW(from: $0) }
        return Dia.shared.save(raws, merge: true)
    }
    
    func upload() async throws {
        update(status: .syncing)
        let nominations = Dia.shared.nominations()
        let jsons = nominations.map { $0.raw.json }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(jsons)
        try await GoogleKit.Drive.shared.upload(data, to: NominationFile.standard.rawValue)
    }
    
    private func update(status: Status) {
        DispatchQueue.main.async {
            self.status = status
        }
    }
    
    private func processMails() {
        async {
            let nominations = Dia.shared.nominations()
            var raws = nominations.map { $0.raw }
            update(status: .processingMails)
            do {
                raws.append(contentsOf: try await Mari.shared.start(with: raws))
                arrange(raws)
            } catch {
                update(status: .idle)
                refreshCompletionHandler(status, 0)
            }
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
            async {
                await queryBrainstorming(list, merged: merged)
            }
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
            async {
                await queryBrainstorming(list, merged: merged)
            }
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
            async {
                await self.queryBrainstorming(list, merged: merged)
            }
        }
        update(status: .requestMatch)
    }
    
    private func queryBrainstorming(_ raws: [ NominationRAW ], merged: Int) async {
        if !UserDefaults.Brainstorming.query {
            saveAndSync(raws, merged: merged)
            return
        }
        let list = raws.filter {
            $0.lngLat == nil && !Brainstorming.isBeforeEpoch(when: TimeInterval($0.resultTime), status: $0.status)
        }
        if list.isEmpty {
            saveAndSync(raws, merged: merged)
            return
        }
        ProgressInspector.shared.set(done: 0, total: list.count)
        update(status: .queryingBrainstorming)
        await withTaskGroup(of: Void.self) { taskGroup in
            for raw in list {
                taskGroup.async {
                    await self.queryBrainstorming(raw)
                }
            }
        }
        saveAndSync(raws, merged: merged)
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
        async {
            if UserDefaults.Google.sync {
                try? await upload()
            }
            update(status: .idle)
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
