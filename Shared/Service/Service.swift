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
    
    typealias BasicCallback = () -> Void
    typealias OnRefreshFinishedCallback = (Int) -> Void
    typealias ImportCompletionHandler = (Int) -> Void
    
    enum ServiceStatus: String {
        case idle               = "service.status.idle"
        case syncing            = "service.status.syncing"
        case processingMails    = "service.status.processingMails"
        case requestMatch       = "service.status.requestMatch"
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
            let nominations = Dia.preview.nominations.sorted { $0.title < $1.title }
            let pack = MatchPack(nominations[index].toRaw())
            pack.candidates = nominations.map { $0.toRaw() }
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
    
    @Published var status: ServiceStatus = .idle
    
    let matchData = MatchData()
    
    private var onRequiresMatch: BasicCallback = { }
    private var onRefreshFinished: OnRefreshFinishedCallback = { _ in }
    
    private init() {

    }
    
    /// Migrate data from potori.json
    func migrateFromGoogleDrive(_ completionHandler: @escaping ImportCompletionHandler) {
        download(.legacy) { count in
            completionHandler(count)
            self.set(status: .idle)
        }
    }
    
    func refresh() {
        if status != .idle || !GoogleKit.Auth.shared.authorized {
            return
        }
        if Preferences.Google.sync {
            download { _ in
                self.processMails()
            }
        } else {
            processMails()
        }
    }
    
    #if os(iOS)
    func registerRefresh() {
        UNUserNotificationCenter
            .requestAuthorization()
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.refreshTaskID, using: nil) { task in
            if let refreshTask = task as? BGAppRefreshTask {
                self.refresh(task: refreshTask)
            }
        }
    }
    
    func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func refresh(task: BGAppRefreshTask) {
        scheduleRefresh()
        onRequiresMatch = {
            UNUserNotificationCenter.push(
                NSLocalizedString("notification.refresh.requiresMatch", comment: "Manually Match Required"),
                NSLocalizedString("notification.refresh.requiresMatch.desc", comment: "Manually Match Required Description")
            )
            task.setTaskCompleted(success: true)
        }
        onRefreshFinished = { count in
            if count > 0 {
                UNUserNotificationCenter.push(
                    NSLocalizedString("notification.refresh.refreshFinished", comment: "Refresh Finished"),
                    String(format: NSLocalizedString("notification.refresh.refreshFinished.desc", comment: "Refresh Finished Description"), count)
                )
            }
            task.setTaskCompleted(success: count > 0)
        }
        refresh()
    }
    #endif
    
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
    
    func importNominations(url: URL) throws -> Int {
        let data = try Data(contentsOf: url)
        return try importNominations(data: data)
    }
    
    @discardableResult
    func importNominations(data: Data) throws -> Int {
        let decoder = JSONDecoder()
        let jsonList = try decoder.decode([NominationJSON].self, from: data)
        let raws = jsonList.map { NominationRAW(from: $0) }
        return save(raws, merge: true)
    }
    
    func exportNominations() -> NominationJSONDocument {
        let nominations = Dia.shared.nominations
        let raws = nominations.map { $0.toRaw() }
        let jsons = raws.map { $0.json }
        return .init(jsons)
    }
    
    private func download(_ file: NominationFile = .standard, completionHandler: @escaping ImportCompletionHandler) {
        self.set(status: .syncing)
        GoogleKit.Drive.shared.download(file.rawValue) { (json: [ NominationJSON ]?) in
            guard let solidJSON = json else {
                completionHandler(0)
                return
            }
            let raws = solidJSON.map { NominationRAW(from: $0) }
            completionHandler(self.save(raws, merge: true))
        }
    }
    
    func upload(_ completionHandler: @escaping () -> Void) {
        set(status: .syncing)
        let nominations = Dia.shared.nominations
        let raws = nominations.map { $0.toRaw() }
        let jsons = raws.map { $0.json }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(jsons) {
            GoogleKit.Drive.shared.upload(data, NominationFile.standard.rawValue, mimeType: "application/json") {
                completionHandler()
            }
        }
    }
    
    private func set(status: ServiceStatus) {
        DispatchQueue.main.async {
            self.status = status
        }
    }
    
    @discardableResult
    private func save(_ raws: [NominationRAW], merge: Bool = false) -> Int {
        let existings = Dia.shared.nominations
        var addCount = 0
        for raw in raws {
            var saved = false
            for nomination in existings {
                if nomination.id != raw.id {
                    continue
                }
                nomination.from(raw, merge: merge)
                saved = true
                break
            }
            if !saved {
                let newNomination = Nomination(context: Dia.shared.viewContext)
                newNomination.from(raw)
                addCount += 1
            }
        }
        Dia.shared.save()
        return addCount
    }
    
    private func processMails() {
        let raws = Dia.shared.nominations.map { $0.toRaw() }
        set(status: .processingMails)
        let started = Mari.shared.start(with: raws) { nominations in
            self.arrange(nominations)
        }
        if !started {
            set(status: .idle)
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
        
        if !matchTargets.isEmpty {
            onRequiresMatch()
            match(matchTargets, from: reduced, merged: mergeCount)
        } else {
            saveAndSync(reduced, mergeCount)
        }
    }
    
    private func match(_ targets: [NominationRAW], from list: [NominationRAW], merged: Int) {
        set(status: .requestMatch)
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
            saveAndSync(list, merged)
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
            self.saveAndSync(list, merged)
        }
    }
    
    private func saveAndSync(_ raws: [NominationRAW], _ mergeCount: Int) {
        let updateCount = save(raws) + mergeCount
        if Preferences.Google.sync {
            upload {
                self.onRefreshFinished(updateCount)
                self.set(status: .idle)
            }
        } else {
            onRefreshFinished(updateCount)
            set(status: .idle)
        }
    }
    
    #if DEBUG
    static var preview: Service = {
        let forPreview = Service()
        forPreview.matchData.packs = [
            MatchPack.preview(0),
            MatchPack.preview(1)
        ]
        return forPreview
    }()
    #endif
}
