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
    
    enum ServiceStatus {
        case idle
        case syncing
        case processingMails
    }
    
    private enum NominationFile: String {
        case standard = "nominations.json"
        case legacy = "potori.json"
    }
    
    static let shared = Service()
    
    private static let progressPartMari = 0.8
    
    @Published var status: ServiceStatus = .idle
    @Published var progress = 0.0
    
    let containerContext: NSManagedObjectContext

    @Published var auth = AuthKit()
    private let mari = Mari()
    private let googleDrive = GoogleDriveKit()

    private var authAnyCancellable: AnyCancellable? = nil
    
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
        mari.onProgress { progress in
            self.handleMariProgress(progress)
        }
        mari.onFinished { nominations in
            self.arrange(nominations)
        }
        mari.updateAuth(auth.auth)
        googleDrive.updateAuth(auth.auth)
        authAnyCancellable = auth.objectWillChange.sink {
            self.mari.updateAuth(self.auth.auth)
            self.googleDrive.updateAuth(self.auth.auth)
            self.objectWillChange.send()
        }
    }
    
    var nominations: [Nomination] {
        do {
            return try containerContext.fetch(Nomination.fetchRequest())
        } catch {
            print("[CoreData][Fetch] Failed: \(error.localizedDescription)")
        }
        return []
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
    
    func refresh() {
        if auth.login {
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
        googleDrive.download(file.rawValue) { data in
            if let solidData = data {
                do {
                    try self.importNominations(data: solidData)
                    callback()
                } catch {
                    return true
                }
            } else if file == .standard {
                self.download(.legacy, callback)
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
            googleDrive.upload(data , "application/json", NominationFile.standard.rawValue) {
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
    
    private func handleMariProgress(_ progress: Double) {
        self.progress = progress * Service.progressPartMari
    }
    
    private func arrange(_ raws: [NominationRAW]) {
        self.progress = Service.progressPartMari
        var reduced: [NominationRAW] = []
        reduced.reserveCapacity(raws.capacity)
        reduced = raws.reduce(into: reduced) { list, raw in
            // Merge
            var merged = false
            for target in list {
                if target.id != raw.id {
                    continue
                }
                if target.status == .pending {
                    target.title = raw.title
                    target.status = raw.status
                    target.reasons = raw.reasons
                    target.resultTime = raw.resultTime
                    target.resultMailId = raw.resultMailId
                    if raw.lngLat != nil {
                        target.lngLat = raw.lngLat
                    }
                } else {
                    target.confirmedTime = raw.confirmedTime
                    target.confirmationMailId = raw.confirmationMailId
                    if target.lngLat == nil {
                        target.lngLat = raw.lngLat
                    }
                }
                merged = true
                break
            }
            if !merged {
                list.append(raw)
            }
        }
        manuallyMatch(reduced)
    }
    
    private func manuallyMatch(_ raws: [NominationRAW]) {
        save(raws)
        if Preferences.Google.sync {
            upload {
                self.status = .idle
            }
        } else {
            status = .idle
        }
    }
    
    #if DEBUG
    static var preview: Service = {
        let forPreview = Service(inMemory: true)
        let viewContext = forPreview.containerContext
        do {
            try forPreview.importNominations(url: Bundle.main.url(forResource: "nominations.json", withExtension: nil)!)
            try viewContext.save()
        } catch {
            fatalError("Unresolved error: \(error.localizedDescription)")
        }
        return forPreview
    }()
    #endif
}
