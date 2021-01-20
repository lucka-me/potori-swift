//
//  Reason.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import Foundation
import CoreData

@objc(Reason)
public class Reason: NSManagedObject {

}

extension Reason {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reason> {
        return NSFetchRequest<Reason>(entityName: "Reason")
    }

    @NSManaged public var code: Int16
    @NSManaged public var nominations: NSSet?

}

// MARK: Generated accessors for nominations
extension Reason {

    @objc(addNominationsObject:)
    @NSManaged public func addToNominations(_ value: Nomination)

    @objc(removeNominationsObject:)
    @NSManaged public func removeFromNominations(_ value: Nomination)

    @objc(addNominations:)
    @NSManaged public func addToNominations(_ values: NSSet)

    @objc(removeNominations:)
    @NSManaged public func removeFromNominations(_ values: NSSet)

}

extension Reason : Identifiable {

}
