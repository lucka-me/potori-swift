//
//  Dia.swift
//  Potori
//
//  Created by Lucka on 28/1/2021.
//

import CoreData

class Dia: ObservableObject {

    static let shared = Dia()
    
    private static let directoryURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: FileManager.appGroupIdentifier)!
        .appendingPathComponent("database", isDirectory: true)
    private static let fileURL = directoryURL
        .appendingPathComponent("default.sqlite")
    
    /// Refresh it to force UI refresh after save Core Data
    @Published private var saveID = UUID().uuidString
    
    let viewContext: NSManagedObjectContext
    
    private init(inMemory: Bool = false) {
        let container = NSPersistentContainer(name: "Potori")
        if inMemory {
            #if DEBUG
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            #endif
        } else {
            if !FileManager.default.fileExists(atPath: Self.fileURL.path) {
                try? FileManager.default.createDirectory(at: Self.directoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            let storeDescription = NSPersistentStoreDescription(url: Self.fileURL)
            //storeDescription.cloudKitContainerOptions = .init(containerIdentifier: "iCloud.dev.lucka.Potori")
            container.persistentStoreDescriptions = [ storeDescription ]
        }
        container.loadPersistentStores { storeDescription, error in
            if let solidError = error {
                // Handle error
                print("[CoreDataKit] Failed to load: \(solidError.localizedDescription)")
            }
        }
        viewContext = container.viewContext
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    var nominations: [Nomination] {
        nominations(matches: nil)
    }
    
    var isNominationsEmpty: Bool {
        countNominations() == 0
    }
    
    func nominations(matches predicate: NSPredicate?) -> [Nomination] {
        let request: NSFetchRequest<Nomination> = Nomination.fetchRequest()
        request.predicate = predicate
        return (try? viewContext.fetch(request)) ?? []
    }
    
    func firstNomination(
        matches predicate: NSPredicate? = nil,
        sortedBy descriptors: [ NSSortDescriptor ] = []
    ) -> Nomination? {
        let request: NSFetchRequest<Nomination> = Nomination.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = descriptors
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
    
    func countNominations(matches predicate: NSPredicate? = nil) -> Int {
        let request: NSFetchRequest<Nomination> = Nomination.fetchRequest()
        request.predicate = predicate
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    func countReasons(matches predicate: NSPredicate? = nil) -> Int {
        let request: NSFetchRequest<Reason> = Reason.fetchRequest()
        request.predicate = predicate
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    func delete(_ nomination: Nomination) {
        viewContext.delete(nomination)
    }
    
    func clear() {
        for nomination in nominations {
            viewContext.delete(nomination)
        }
    }
    
    @discardableResult
    func save(_ raws: [ NominationRAW ], merge: Bool = false) -> Int {
        let existings = nominations
        var count = 0
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
                count += 1
            }
        }
        save()
        return count
    }
    
    /// Save changes and refresh the UI by refreshing saveID
    func save() {
        if !viewContext.hasChanges {
            return
        }
        do {
            try viewContext.save()
            DispatchQueue.main.async {
                self.saveID = UUID().uuidString
            }
        } catch {
            print("[CoreData][Save] Failed: \(error.localizedDescription)")
        }
    }
    
    func importNominations(_ url: URL) throws -> Int {
        let data = try Data(contentsOf: url)
        return try importNominations(data)
    }
    
    func exportNominations() -> NominationJSONDocument {
        let jsons = nominations.map { $0.raw.json }
        return .init(jsons)
    }
    
    @discardableResult
    private func importNominations(_ data: Data) throws -> Int {
        let decoder = JSONDecoder()
        let jsonList = try decoder.decode([ NominationJSON ].self, from: data)
        let raws = jsonList.map { NominationRAW(from: $0) }
        return save(raws, merge: true)
    }
    
    #if DEBUG
    static let preview: Dia = {
        let forPreview = Dia(inMemory: true)
        let viewContext = forPreview.viewContext
        do {
            let data = try Data(contentsOf: Bundle.main.url(forResource: "nominations.json", withExtension: nil)!)
            let decoder = JSONDecoder()
            let jsons = try decoder.decode([NominationJSON].self, from: data)
            let raws = jsons.map { NominationRAW(from: $0) }
            for raw in raws {
                let newNomination = Nomination(context: viewContext)
                newNomination.from(raw)
            }
            try viewContext.save()
        } catch {
            fatalError("Unresolved error: \(error.localizedDescription)")
        }
        return forPreview
    }()
    #endif
}
