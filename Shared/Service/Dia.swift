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
    
    func firstNomination(matches predicate: NSPredicate) -> Nomination? {
        let request: NSFetchRequest<Nomination> = Nomination.fetchRequest()
        request.predicate = predicate
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
    
    func firstNomination(sortBy descriptors: [NSSortDescriptor]) -> Nomination? {
        let request: NSFetchRequest<Nomination> = Nomination.fetchRequest()
        request.sortDescriptors = descriptors
        request.fetchLimit = 1
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
    
    func delete(_ nomination: Nomination) {
        viewContext.delete(nomination)
    }
    
    func clear() {
        for nomination in nominations {
            viewContext.delete(nomination)
        }
    }
    
    /// Save changes and refresh the UI by refreshing saveID
    func save() {
        save(with: viewContext)
    }
    
    /// Save changes in designated view context
    /// - Parameter context: The view context to save
    func save(with context: NSManagedObjectContext) {
        if !context.hasChanges {
            return
        }
        do {
            try context.save()
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
