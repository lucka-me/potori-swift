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
        let container = NSPersistentCloudKitContainer(name: "Potori")
        if inMemory {
            #if DEBUG
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            #endif
        } else {
            if !FileManager.default.fileExists(atPath: Self.fileURL.path) {
                try? FileManager.default.createDirectory(at: Self.directoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            let storeDescription = NSPersistentStoreDescription(url: Self.fileURL)
            //storeDescription.cloudKitContainerOptions = .init(containerIdentifier: "")
            container.persistentStoreDescriptions = [ storeDescription ]
        }
        container.loadPersistentStores { storeDescription, error in
            if let solidError = error {
                // Handle error
                print("[CoreDataKit] Failed to load: \(solidError.localizedDescription)")
            }
        }
        viewContext = container.viewContext
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    var nominations: [Nomination] {
        do {
            return try viewContext.fetch(Nomination.fetchRequest())
        } catch {
            print("[CoreData][Fetch] Failed: \(error.localizedDescription)")
        }
        return []
    }
    
    var isNominationsEmpty: Bool {
        countNominations() == 0
    }
    
    func nomination(by id: String) -> Nomination? {
        let request: NSFetchRequest<Nomination> = Nomination.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try? viewContext.fetch(request).first
    }
    
    func countNominations(_ withPredicate: NSPredicate? = nil) -> Int {
        let request: NSFetchRequest<Nomination> = Nomination.fetchRequest()
        request.predicate = withPredicate
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    func countReasons(_ withPredicate: NSPredicate? = nil) -> Int {
        let request: NSFetchRequest<Reason> = Reason.fetchRequest()
        request.predicate = withPredicate
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    func clear() {
        for nomination in nominations {
            viewContext.delete(nomination)
        }
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
    
    #if DEBUG
    static var preview: Dia = {
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
