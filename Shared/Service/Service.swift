//
//  ModelData.swift
//  Potori
//
//  Created by Lucka on 29/12/2020.
//

import Foundation
import Combine
import CoreData

final class Service: ObservableObject {
    
    typealias BasicCallback = () -> Void
    
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
    
    private static let progressPartMari = 0.8
    private static let progressPartMatch = 0.2
    
    @Published var status: ServiceStatus = .idle
    @Published var progress = 0.0

    @Published var google = GoogleKit()
    @Published var match = MatchManager()

    let containerContext: NSManagedObjectContext
    private let mari = Mari()

    private var googleAnyCancellable: AnyCancellable? = nil
    private var matchAnyCancellable: AnyCancellable? = nil
    
    private init(inMemory: Bool = false) {
        let container = NSPersistentCloudKitContainer(name: "Potori")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { storeDescription, error in
            if let solidError = error {
                // Handle error
                print("[CoreData] Failed to load: \(solidError.localizedDescription)")
            }
        }
        containerContext = container.viewContext
        containerContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
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
    
    func countNominations(_ withPredicate: NSPredicate? = nil) -> Int {
        let request: NSFetchRequest<Nomination> = Nomination.fetchRequest()
        request.predicate = withPredicate
        return (try? containerContext.count(for: request)) ?? 0
    }
    
    func countReasons(_ withPredicate: NSPredicate? = nil) -> Int {
        let request: NSFetchRequest<Reason> = Reason.fetchRequest()
        request.predicate = withPredicate
        return (try? containerContext.count(for: request)) ?? 0
    }
    
    var nominations: [Nomination] {
        do {
            return try containerContext.fetch(Nomination.fetchRequest())
        } catch {
            print("[CoreData][Fetch] Failed: \(error.localizedDescription)")
        }
        return []
    }
    
    var isNominationsEmpty: Bool {
        (try? containerContext.count(for: Nomination.fetchRequest())) == 0
    }
    
    func clear() {
        for nomination in nominations {
            containerContext.delete(nomination)
        }
    }
    
    func save() {
        do {
            try containerContext.save()
        } catch {
            print("[CoreData][Save] Failed: \(error.localizedDescription)")
        }
    }
    
    /// Migrate data from potori.json
    func migrateFromGoogleDrive() {
        download(.legacy) {
            self.status = .idle
        }
    }
    
    func refresh() {
        if google.auth.login {
            progress = 0.0
            if Preferences.Google.sync {
                download {
                    self.processMails()
                }
            } else {
                processMails()
            }
        }
    }
    
    func sync(performDownload: Bool = true, performUpload: Bool = true) {
        if !performDownload && !performUpload {
            return
        }
        if performDownload {
            download {
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
    
    func importNominations(result: Result<URL, Error>) {
        guard let url = try? result.get() else {
            return
        }
        do {
            try importNominations(url: url)
        } catch {
            
        }
    }
    
    func importNominations(url: URL) throws {
        let data = try Data(contentsOf: url)
        try importNominations(data: data)
    }
    
    func importNominations(data: Data) throws {
        let decoder = JSONDecoder()
        let jsonList = try decoder.decode([NominationJSON].self, from: data)
        let raws = jsonList.map { NominationRAW(from: $0) }
        save(raws, merge: true)
    }
    
    func exportNominations() -> NominationJSONDocument {
        let list = nominations
        let raws = list.map { $0.toRaw() }
        let jsonList = raws.map { $0.json }
        return .init(jsonList)
    }
    
    private func download(_ file: NominationFile = .standard, _ callback: @escaping BasicCallback) {
        status = .syncing
        google.drive.download(file.rawValue) { data in
            if let solidData = data {
                do {
                    try self.importNominations(data: solidData)
                    callback()
                } catch {
                    return true
                }
            } else {
                callback()
            }
            return false
        }
    }
    
    func upload(_ callback: @escaping BasicCallback) {
        status = .syncing
        let list = nominations
        let raws = list.map { $0.toRaw() }
        let jsonList = raws.map { $0.json }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(jsonList)
            google.drive.upload(data , "application/json", NominationFile.standard.rawValue) {
                callback()
            }
        } catch {
            
        }
    }
    
    private func save(_ raws: [NominationRAW], merge: Bool = false) {
        let existings = nominations
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
                let newNomination = Nomination(context: containerContext)
                newNomination.from(raw)
            }
        }
        save()
    }
    
    private func processMails() {
        status = .processingMails
        let raws = nominations.map { $0.toRaw() }
        mari.start(raws)
    }
    
    private func arrange(_ raws: [NominationRAW]) {
        self.progress = Service.progressPartMari
        var reduced: [NominationRAW] = []
        var matchTargets: [NominationRAW] = []
        reduced.reserveCapacity(raws.capacity)
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
                    break
                }
            }
            if !merged {
                list.append(raw)
            }
        }
        
        if !matchTargets.isEmpty {
            let pendings = reduced.filter { $0.status == .pending }
            print("Service.arrange() match \(matchTargets.count) targets from \(pendings.count) candidates")
            match.start(matchTargets, pendings) { matched in
                reduced = matched.reduce(into: reduced) { list, raw in
                    var merged = false
                    for target in list {
                        if target.merge(raw) {
                            merged = true
                            break
                        }
                    }
                    if !merged {
                        list.append(raw)
                    }
                }
                self.saveAndSync(reduced)
            }
        } else {
            saveAndSync(reduced)
        }
    }
    
    private func saveAndSync(_ raws: [NominationRAW]) {
        save(raws)
        if Preferences.Google.sync {
            upload {
                self.progress = 1.0
                self.status = .idle
            }
        } else {
            self.progress = 1.0
            status = .idle
        }
    }
    
    #if DEBUG
    static var preview: Service {
        let forPreview = Service(inMemory: true)
        let viewContext = forPreview.containerContext
        do {
            try forPreview.importNominations(url: Bundle.main.url(forResource: "nominations.json", withExtension: nil)!)
            try viewContext.save()
        } catch {
            fatalError("Unresolved error: \(error.localizedDescription)")
        }
        return forPreview
    }
    #endif
}
