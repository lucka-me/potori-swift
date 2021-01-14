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
    @NSManaged public var reasons: [Int16]
    
    @NSManaged public var confirmedTime: Date
    @NSManaged public var confirmationMailId: String
    
    @NSManaged public var resultTime: Date
    @NSManaged public var resultMailId: String
    
    @NSManaged public var hasLngLat: Bool
    @NSManaged public var longitude: Double
    @NSManaged public var latitude: Double
}

extension Nomination : Identifiable {
    
    static let defaultLatitude = 22.309510748206023
    static let defaultLongitude = 114.1024431532275
    
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
    var reasonsData: [Umi.Reason] {
        set {
            reasons = newValue.map { $0.code }
        }
        get {
            reasons.map {
                (Umi.shared.reason[$0] ?? Umi.shared.reason[Umi.Reason.undeclared]!)
            }
        }
    }
    
    var imageURL: String {
        return "https://lh3.googleusercontent.com/\(image)"
    }
    
    var brainstormingURL: URL {
        return URL(string: "https://brainstorming.azurewebsites.net/watermeter.html#\(id)")!
    }
    
    var intelURL: URL {
        return URL(string: "https://intel.ingress.com/intel?ll=\(latitude),\(longitude)&z=18")!
    }
    
    var location: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
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
            reasons = raw.reasons
        } else if !raw.reasons.isEmpty {
            for reason in raw.reasons {
                if !reasons.contains(reason) {
                    reasons.append(reason)
                }
            }
        }
        
        if !merge || raw.confirmedTime > 0 {
            confirmedTime = Date(timeIntervalSince1970: TimeInterval(raw.confirmedTime / 1000))
        }
        if !merge || !raw.confirmationMailId.isEmpty {
            confirmationMailId = raw.confirmationMailId
        }
        if !merge || raw.resultTime > 0 {
            resultTime = Date(timeIntervalSince1970: TimeInterval(raw.resultTime / 1000))
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
        raw.reasons = reasons
        raw.confirmedTime = UInt64(confirmedTime.timeIntervalSince1970 * 1000)
        raw.confirmationMailId = confirmationMailId
        raw.resultTime = UInt64(resultTime.timeIntervalSince1970 * 1000)
        raw.resultMailId = resultMailId
        if hasLngLat {
            raw.lngLat = LngLat(lng: longitude, lat: latitude)
        } else {
            raw.lngLat = nil
        }
        return raw
    }
}
