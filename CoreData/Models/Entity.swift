//
//  Entity.swift
//  CoreDataMnager
//
//  Created by Sergey on 11/21/18.
//  Copyright © 2018 sblinov.com. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject: Entity { }

protocol Entity: class {
    var descriptionName: String { get }
    var dateStamp: Date { get }
}

extension Entity where Self: NSManagedObject {
    
    static func createEntity(context: NSManagedObjectContext = CoreDataManager.shared.privateContext) -> Self? {
        let entity = NSEntityDescription.entity(forEntityName: Self.entity().managedObjectClassName, in: context)
        guard let object = NSManagedObject(entity: entity!, insertInto: context) as? Self else { fatalError("Error create Entity") }
        return object
    }
    
    func delete(mainContext: NSManagedObjectContext = CoreDataManager.shared.mainContext) {
        let deleteRequest = NSBatchDeleteRequest(objectIDs: [self.objectID])
        do {
            try mainContext.execute(deleteRequest)
            try mainContext.save()
        } catch {
            print("Failed daleteAll")
        }
    }
    
    static func all(context: NSManagedObjectContext = CoreDataManager.shared.mainContext,
                    predicate: NSPredicate? = nil,
                    sort: [NSSortDescriptor]? = nil) -> [Self]? {
        guard let request = fetchRequest(predicate: predicate, sort: sort) as? NSFetchRequest<Self> else { return nil }
        do {
            return try context.fetch(request)
        } catch {
            print("Failed all")
            return nil
        }
    }
    
    static func deleteAll(context: NSManagedObjectContext = CoreDataManager.shared.privateContext,
                          predicate: NSPredicate? = nil,
                          sort: [NSSortDescriptor]? = nil) -> Bool {
        let request = fetchRequest(predicate: predicate, sort: sort)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        do {
            try context.execute(deleteRequest)
            try context.save()
            return true
        } catch {
            print("Failed daleteAll")
            return false
        }
    }
    
    private static func fetchRequest(predicate: NSPredicate? = nil,
                                     sort: [NSSortDescriptor]? = nil) -> NSFetchRequest<NSFetchRequestResult> {
        let request = Self.fetchRequest()
        request.predicate = predicate
        request.returnsObjectsAsFaults = false
        request.sortDescriptors = sort
        
        return request
    }
    
    var descriptionName: String {
        return Self.description()
    }
    
    var dateStamp: Date {
        return Date()
    }
}
