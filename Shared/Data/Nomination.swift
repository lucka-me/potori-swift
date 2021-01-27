//
//  Nomination+CoreDataClass.swift
//  Potori
//
//  Created by Lucka on 4/1/2021.
//
//

import Foundation
import CoreData
import CoreLocation

@objc(Nomination)
public class Nomination: NSManagedObject {

}

extension Nomination {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Nomination> {
        return NSFetchRequest<Nomination>(entityName: "Nomination")
    }

    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var image: String
    @NSManaged public var scanner: Int16
    
    @NSManaged public var status: Int16
    @NSManaged public var reasons: NSSet

    @NSManaged public var confirmedTime: Date
    @NSManaged public var confirmationMailId: String
    
    @NSManaged public var resultTime: Date
    @NSManaged public var resultMailId: String
    
    @NSManaged public var hasLngLat: Bool
    @NSManaged public var longitude: Double
    @NSManaged public var latitude: Double
}

// MARK: Generated accessors for reasons
extension Nomination {

    @objc(addReasonsObject:)
    @NSManaged public func addToReasons(_ value: Reason)

    @objc(removeReasonsObject:)
    @NSManaged public func removeFromReasons(_ value: Reason)

    @objc(addReasons:)
    @NSManaged public func addToReasons(_ values: NSSet)

    @objc(removeReasons:)
    @NSManaged public func removeFromReasons(_ values: NSSet)

}

extension Nomination {
    static let defaultLatitude = 22.309510748206023
    static let defaultLongitude = 114.1024431532275
    
    static let sortDescriptorsByDate = [
        NSSortDescriptor(keyPath: \Nomination.resultTime, ascending: false),
        NSSortDescriptor(keyPath: \Nomination.confirmedTime, ascending: false)
    ]
}

extension Nomination : Identifiable {
    
    var scannerCode: Umi.Scanner.Code {
        set { scanner = newValue.rawValue }
        get { Umi.Scanner.Code(rawValue: scanner) ?? .unknown }
    }
    
    var scannerData: Umi.Scanner {
        set { scannerCode = newValue.code }
        get { Umi.shared.scanner[scannerCode]! }
    }
    
    var statusCode: Umi.Status.Code {
        set { status = newValue.rawValue }
        get { Umi.Status.Code(rawValue: status) ?? .pending }
    }

    var statusData: Umi.Status {
        set { statusCode = newValue.code }
        get { Umi.shared.status[statusCode]! }
    }
    
    var reasonsCode: [Umi.Reason.Code] {
        set {
            removeFromReasons(reasons)
            if let solidContext = managedObjectContext {
                for code in newValue {
                    let reason = Reason(context: solidContext)
                    reason.code = code
                    addToReasons(reason)
                }
            }
        }
        get {
            let typedSet = reasons as? Set<Reason> ?? []
            return typedSet.map { $0.code }.sorted()
        }
    }

    var reasonsData: [Umi.Reason] {
        reasonsCode.compactMap { Umi.shared.reason[$0] }
    }
    
    var imageURL: String {
        NominationRAW.generateImageURL(image)
    }
    
    var brainstormingURL: URL {
        URL(string: "https://brainstorming.azurewebsites.net/watermeter.html#\(id)")!
    }
    
    var intelURL: URL {
        URL(string: "https://intel.ingress.com/intel?ll=\(latitude),\(longitude)&z=18")!
    }
    
    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: hasLngLat ? latitude : Nomination.defaultLatitude,
            longitude: hasLngLat ? longitude : Nomination.defaultLongitude
        )
    }
    
    func generateId() {
        id = NominationRAW.generateId(image)
    }
    
    /// Import data from raw
    /// - Parameter raw: The raw object to import from
    /// - Parameter merge: Simply overwrite all properties if `false`, ignore the missing part like an unknown `scanner` if `true`
    func from(_ raw: NominationRAW, merge: Bool = false) {
        id = raw.id
        title = raw.title
        image = raw.image
        if !merge || raw.scanner != .unknown {
            scanner = raw.scanner.rawValue
        }
        
        if !merge || raw.status != .pending {
            status = raw.status.rawValue
        }
        if !merge {
            removeFromReasons(reasons)
        }
        if let solidContext = managedObjectContext {
            for code in raw.reasons {
                let reason = Reason(context: solidContext)
                reason.code = code
                addToReasons(reason)
            }
        }
        
        if !merge || raw.confirmedTime > 0 {
            confirmedTime = Date(timeIntervalSince1970: TimeInterval(raw.confirmedTime))
        }
        if !merge || !raw.confirmationMailId.isEmpty {
            confirmationMailId = raw.confirmationMailId
        }
        if !merge || raw.resultTime > 0 {
            resultTime = Date(timeIntervalSince1970: TimeInterval(raw.resultTime))
        }
        if !merge || !raw.resultMailId.isEmpty {
            resultMailId = raw.resultMailId
        }
        
        if let solidLngLat = raw.lngLat {
            hasLngLat = true
            longitude = solidLngLat.lng
            latitude = solidLngLat.lat
        } else if !merge {
            hasLngLat = false
        }
    }
    
    func toRaw() -> NominationRAW {
        let raw = NominationRAW()
        raw.id = id
        raw.title = title
        raw.image = image
        raw.scanner = Umi.Scanner.Code(rawValue: scanner) ?? .unknown
        raw.status = Umi.Status.Code(rawValue: status) ?? .pending
        raw.reasons = reasonsCode
        raw.confirmedTime = UInt64(confirmedTime.timeIntervalSince1970)
        raw.confirmationMailId = confirmationMailId
        raw.resultTime = UInt64(resultTime.timeIntervalSince1970)
        raw.resultMailId = resultMailId
        if hasLngLat {
            raw.lngLat = LngLat(lng: longitude, lat: latitude)
        } else {
            raw.lngLat = nil
        }
        return raw
    }
    
    func toWidgetJSON() -> NominationWidgetJSON {
        .init(id: id, title: title, image: image, status: status)
    }
}
