//
//  ModelData.swift
//  Potori
//
//  Created by Lucka on 29/12/2020.
//

import Foundation
import Combine
import CoreData

#if os(iOS)
import BackgroundTasks
import UserNotifications
#endif

final class Service: ObservableObject {
    
    typealias BasicCallback = () -> Void
    typealias OnRefreshFinishedCallback = (Int) -> Void
    typealias OnDownloadFinishedCallback = (Int) -> Void
    
    enum ServiceStatus: String {
        case idle               = "service.status.idle"
        case syncing            = "service.status.syncing"
        case processingMails    = "service.status.processingMails"
    }
    
    private enum NominationFile: String {
        case standard = "nominations.json"
        case legacy = "potori.json"
    }
    
    static let shared = Service()
    
    #if os(iOS)
    private static let refreshTaskID = "moe.lucka.Potori.refresh"
    #endif
    private static let progressPartMari = 0.8
    private static let progressPartMatch = 0.2
    
    @Published var status: ServiceStatus = .idle
    @Published var progress = 0.0

    @Published var google = GoogleKit()
    @Published var match = MatchKit()
    
    private let mari = Mari()
    private var onRequiresMatch: BasicCallback = { }
    private var onRefreshFinished: OnRefreshFinishedCallback = { _ in }

    private var googleAnyCancellable: AnyCancellable? = nil
    private var matchAnyCancellable: AnyCancellable? = nil
    
    private init() {
        mari.onProgress { progress in
            self.progress = progress * Service.progressPartMari
        }
        mari.onFinished { nominations in
            self.arrange(nominations)
        }
        mari.updateAuth(google.auth.auth)
        
        match.onProgress { progress in
            self.progress = Service.progressPartMari + progress * Service.progressPartMatch
        }
        
        googleAnyCancellable = google.objectWillChange.sink {
            self.mari.updateAuth(self.google.auth.auth)
            self.objectWillChange.send()
        }
        matchAnyCancellable = match.objectWillChange.sink {
            self.objectWillChange.send()
        }
    }
    
    /// Migrate data from potori.json
    func migrateFromGoogleDrive(_ callback: @escaping OnDownloadFinishedCallback) {
        download(.legacy) { count in
            callback(count)
            self.status = .idle
        }
    }
    
    func refresh() {
        if status != .idle || !google.auth.login {
            return
        }
        DispatchQueue.main.async {
            self.progress = 0.0
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
                    self.upload {  self.status = .idle }
                } else {
                    self.status = .idle
                }
            }
        } else {
            upload { self.status = .idle }
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
    
    private func download(_ file: NominationFile = .standard, _ callback: @escaping OnDownloadFinishedCallback) {
        DispatchQueue.main.async {
            self.status = .syncing
        }
        google.drive.download(file.rawValue) { data in
            if let solidData = data {
                do {
                    let count = try self.importNominations(data: solidData)
                    callback(count)
                } catch {
                    return true
                }
            } else {
                callback(0)
            }
            return false
        }
    }
    
    func upload(_ callback: @escaping BasicCallback) {
        DispatchQueue.main.async {
            self.status = .syncing
        }
        let nominations = Dia.shared.nominations
        let raws = nominations.map { $0.toRaw() }
        let jsons = raws.map { $0.json }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(jsons) {
            google.drive.upload(data, "application/json", NominationFile.standard.rawValue) {
                callback()
            }
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
        DispatchQueue.main.async {
            self.status = .processingMails
        }
        let raws = Dia.shared.nominations.map { $0.toRaw() }
        mari.start(raws)
    }
    
    private func arrange(_ raws: [NominationRAW]) {
        DispatchQueue.main.async {
            self.progress = Service.progressPartMari
        }
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
            let pendings = reduced.filter { $0.status == .pending }
            onRequiresMatch()
            match.start(matchTargets, pendings) { matched in
                reduced = matched.reduce(into: reduced) { list, raw in
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
                self.saveAndSync(reduced, mergeCount)
            }
        } else {
            saveAndSync(reduced, mergeCount)
        }
    }
    
    private func saveAndSync(_ raws: [NominationRAW], _ mergeCount: Int) {
        let updateCount = save(raws) + mergeCount
        if Preferences.Google.sync {
            upload {
                self.progress = 1.0
                DispatchQueue.main.async {
                    self.status = .idle
                }
                self.onRefreshFinished(updateCount)
            }
        } else {
            progress = 1.0
            DispatchQueue.main.async {
                self.status = .idle
            }
            onRefreshFinished(updateCount)
        }
    }
}
