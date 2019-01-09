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

protocol Entity: class { }

extension Entity where Self: NSManagedObject {

    static func createEntity(manager: StoreManager = CoreDataManager.shared) -> Self? {
        guard let object = NSEntityDescription.insertNewObject(forEntityName: self.className,
                                                               into: manager.privateContext) as? Self else { return nil }
        return object
    }
    
    static func all(manager: StoreManager = CoreDataManager.shared,
                    predicate: NSPredicate? = nil,
                    sort: [NSSortDescriptor]? = nil) -> [Self]? {
        guard let request = fetchRequest(predicate: predicate, sort: sort) as? NSFetchRequest<Self> else { return nil }
        
        return try? manager.mainContext.fetch(request)
    }
    
    static func deleteAll(manager: StoreManager = CoreDataManager.shared,
                          predicate: NSPredicate? = nil,
                          sort: [NSSortDescriptor]? = nil,
                          completion:((SaveStatus) -> Void)? = nil) {
        let request = fetchRequest(predicate: predicate, sort: sort)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        do {
            try manager.privateContext.execute(deleteRequest)
            manager.save(nil) { status in
                completion?(status)
            }
        } catch {
            print("Failed daleteAll")
        }
    }
    
    static func fetchedResultsController(manager: StoreManager = CoreDataManager.shared,
                                         predicate: NSPredicate? = nil,
                                         sort: [NSSortDescriptor]? = nil,
                                         cacheName: String? = nil) -> NSFetchedResultsController<Self> {
        let request = fetchRequest(predicate: predicate, sort: sort)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                  managedObjectContext: manager.mainContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: cacheName)
        return fetchedResultsController as! NSFetchedResultsController<Self>
    }
    
    private static func fetchRequest(predicate: NSPredicate? = nil,
                                     sort: [NSSortDescriptor]? = nil) -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: self.className)
        request.predicate = predicate
        request.returnsObjectsAsFaults = false
        request.sortDescriptors = sort
        
        return request
    }
    
    func delete(manager: StoreManager = CoreDataManager.shared,
                completion:((SaveStatus)-> Void)? = nil) {
        manager.mainContext.delete(self)
        manager.save(nil) { status in
            completion?(status)
        }
    }
}
