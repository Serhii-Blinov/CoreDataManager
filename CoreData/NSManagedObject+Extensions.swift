//
//   NSManagedObject+Extensions.swift
//  CoreDataManager
//
//  Created by Serhii on 29.05.2020.
//  Copyright © 2020 sblinov.com. All rights reserved.
//

import CoreData

extension NSManagedObject: Entity { }

protocol Entity: class { }

extension Entity where Self: NSManagedObject {
    
    static var manager: StoreManager {
        return CoreDataManager.shared
    }
    
    static func createEntity() -> Self? {
        return NSEntityDescription.insertNewObject(forEntityName: self.className, into: manager.privateContext) as? Self
    }
    
    static func count(predicate: NSPredicate? = nil,
                      sort: [NSSortDescriptor]? = nil) -> Int {
        guard let request = fetchRequest(predicate: predicate, sort: sort) as? NSFetchRequest<Self>,
            let result = try? manager.threadContext.count(for: request) else { return 0 }
        
        return result
    }
    
    static func all(predicate: NSPredicate? = nil,
                    sort: [NSSortDescriptor]? = nil) -> [Self]? {
        guard let request = fetchRequest(predicate: predicate, sort: sort) as? NSFetchRequest<Self> else { return nil }
        
        return try? manager.threadContext.fetch(request)
    }
    
    static func allAsync(predicate: NSPredicate? = nil,
                    sort:[NSSortDescriptor]? = nil,
                    completion:(([Self]) -> Void)? = nil) {
        guard let request = fetchRequest(predicate: predicate, sort: sort) as? NSFetchRequest<Self> else { return }
        
        let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: request) { asynchronousFetchResult in
            
            DispatchQueue.main.async {
                completion?(asynchronousFetchResult.finalResult ?? [Self]())
            }
        }
        do {
            try manager.privateContext.execute(asyncRequest)
        } catch {
            print("Failed fetch all items ")
        }
    }
    
    static func deleteAll(predicate: NSPredicate? = nil,
                          sort: [NSSortDescriptor]? = nil,
                          completion:((SaveStatus) -> Void)? = nil) {
        manager.save(async: true, performBlock: {
            let allObjects = all()
            allObjects?.forEach {
                let object = manager.threadContext.object(with: $0.objectID)
                manager.threadContext.delete(object)
            }
        }) { status in
            completion?(status)
        }
    }
    
    static func deleteAllAsync(predicate: NSPredicate? = nil,
                               sort: [NSSortDescriptor]? = nil,
                               completion: ((SaveStatus)-> Void)? = nil) {
        guard let request = fetchRequest(predicate: predicate, sort: sort) as? NSFetchRequest<Self> else { return }
        let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: request) { asynchronousFetchResult in
            manager.save(async: true,
                         performBlock: {
                            asynchronousFetchResult.finalResult?.forEach { manager.threadContext.delete($0 as NSManagedObject) }
            }, completion: { status in
                completion?(status)
            })
        }
        
        do {
            try manager.privateContext.execute(asyncRequest)
        } catch {
            print("Failed fetch all items. \(error.localizedDescription)")
        }
    }
    
    static func fetchedResultsController(predicate: NSPredicate? = nil,
                                         sort: [NSSortDescriptor]? = nil,
                                         cacheName: String? = nil) -> NSFetchedResultsController<Self> {
        let request = fetchRequest(predicate: predicate, sort: sort)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                  managedObjectContext: manager.threadContext,
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
    
    func delete(async: Bool = true, completion:((SaveStatus)-> Void)? = nil) {
        let manager = Self.manager
        manager.save(async: async,
                     performBlock: {
                        let context = manager.threadContext
                        let object = context.object(with: self.objectID)
                        manager.threadContext.delete(object)
        }, completion: completion)
    }
}
