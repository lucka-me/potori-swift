//
//  ModelData.swift
//  Potori
//
//  Created by Lucka on 29/12/2020.
//

import Foundation

final class Service: ObservableObject {
    
    enum ErrorType: Error {
        case processing
        case matchRequired
    }
    
    enum Status {
        case idle
        case syncing
        case processingMails
        case requestMatch
        case queryingBrainstorming
    }
    
    class MatchPack: Identifiable, ObservableObject {
        
        let id = UUID()
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
        var packs: [ MatchPack ] = []
        var callback: () -> Void = { }
    }
    
    private enum NominationFile: String {
        case standard = "nominations.json"
        case legacy = "potori.json"
    }
    
    static let shared = Service()
    
    @Published var status: Status = .idle
    
    let matchData = MatchData()
    
    private init() { }
    
    @discardableResult
    func refresh(throwWhenMatchRequired: Bool = false) async throws -> Int {
        if status != .idle {
            throw ErrorType.processing
        }
        if UserDefaults.Google.sync {
            do {
                try await download()
            } catch {
                await update(status: .idle)
                throw error
            }
        }
        let existingNominations = Dia.shared.nominations()
        var raws = existingNominations.map { $0.raw }
        await update(status: .processingMails)
        do {
            let newRaws = try await Mari.shared.start(with: raws)
            raws.append(contentsOf: newRaws)
        } catch {
            await update(status: .idle)
            throw error
        }
        var matchTargets: [ NominationRAW ] = []
        var mergeCount = 0
        raws = raws.reduce(into: []) { list, raw in
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
        if !matchTargets.isEmpty {
            let pendings = raws.filter { $0.status == .pending }
            let packs: [MatchPack] = matchTargets
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
            if !packs.isEmpty {
                if throwWhenMatchRequired {
                    await update(status: .idle)
                    throw ErrorType.matchRequired
                }
                await update(status: .requestMatch)
                await match(packs)
            }
        }
        if UserDefaults.Brainstorming.query {
            let queryList = raws.filter {
                $0.lngLat == nil && !Brainstorming.isBeforeEpoch(when: TimeInterval($0.resultTime), status: $0.status)
            }
            if !queryList.isEmpty {
                ProgressInspector.shared.set(done: 0, total: queryList.count)
                await update(status: .queryingBrainstorming)
                await withTaskGroup(of: Void.self) { taskGroup in
                    for raw in queryList {
                        taskGroup.addTask {
                            let record = try? await Brainstorming.shared.query(raw.id)
                            if let solidRecord = record {
                                raw.lngLat = .init(lng: solidRecord.lng, lat: solidRecord.lat)
                            }
                            ProgressInspector.shared.step()
                        }
                    }
                }
            }
        }
        let updateCount = await Dia.shared.save(raws) + mergeCount
        if UserDefaults.Google.sync {
            do {
                try await upload()
            } catch {
                await update(status: .idle)
                throw error
            }
        }
        await update(status: .idle)
        return updateCount
    }
    
    func sync(performDownload: Bool = true, performUpload: Bool = true) async throws -> Int {
        var count = 0
        if performUpload {
            do {
                count = try await download()
            } catch {
                await update(status: .idle)
                throw error
            }
        }
        if performUpload {
            do {
                try await upload()
            } catch {
                await update(status: .idle)
                throw error
            }
        }
        await update(status: .idle)
        return count
    }
    
    /// Migrate data from potori.json
    func migrateFromGoogleDrive() async throws -> Int {
        let count: Int
        do {
            count = try await download(.legacy)
        } catch {
            await update(status: .idle)
            throw error
        }
        await update(status: .idle)
        return count
    }
    
    @discardableResult
    private func download(_ file: NominationFile = .standard) async throws -> Int {
        await update(status: .syncing)
        guard
            let jsons: [ NominationJSON ] = try await GoogleKit.Drive.shared.download(file.rawValue)
        else {
            return 0
        }
        let raws = jsons.map { NominationRAW(from: $0) }
        return await Dia.shared.save(raws, merge: true)
    }
    
    private func upload() async throws {
        await update(status: .syncing)
        let nominations = Dia.shared.nominations()
        let jsons = nominations.map { $0.raw.json }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(jsons)
        try await GoogleKit.Drive.shared.upload(data, to: NominationFile.standard.rawValue)
    }
    
    @MainActor
    private func update(status: Status) {
        self.status = status
    }
    
    private func match(_ packs: [ MatchPack ]) async {
        matchData.packs = packs
        return await withUnsafeContinuation { continuation in
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
                    selected.merge(pack.target)
                }
                self.matchData.packs = []
                continuation.resume()
            }
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
