//
//   NSManagedObject+Extensions.swift
//  CoreDataManager
//
//  Created by Serhii on 29.05.2020.
//  Copyright © 2020 sblinov.com. All rights reserved.
//

import CoreData

extension NSManagedObject: Entity {
    
    static var manager: StoreManager {
        return CoreDataManager.shared
    }
}

protocol Entity: AnyObject {
    static var manager: StoreManager { get }
}

protocol StoreManager {
    var modelName: String { get }
    var threadContext: NSManagedObjectContext { get }
    var privateContext: NSManagedObjectContext { get }
    
    func save(async: Bool, performBlock: (()-> Void)?, completion: ((SaveStatus)-> Void)?)
}

extension Entity where Self: NSManagedObject {
    
    init?(managedObjectContext: NSManagedObjectContext = CoreDataManager.shared.privateContext) {
        let eName = type(of: self).className
        guard let entity = NSEntityDescription.entity(forEntityName: eName, in: managedObjectContext) else { return nil }
        self.init(entity: entity, insertInto: managedObjectContext)
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
    
    static func singleFetchedResultController(predicate: NSPredicate? = nil,
                                              managedObjectContext: NSManagedObjectContext = manager.threadContext,
                                              onChange: @escaping OnChange<Self>) -> SingleFetchedResultController<Self> {
        let fetchRC: SingleFetchedResultController<Self> = SingleFetchedResultController(predicate: predicate,
                                                                                         managedObjectContext: managedObjectContext,
                                                                                         onChange: onChange)
        
        return fetchRC
        
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

public protocol EntityNameProviding {
    static func entityName() -> String
}

extension NSManagedObject: EntityNameProviding {
    public static func entityName() -> String {
        return self.className
    }
}

public enum ChangeType {
    case firstFetch
    case insert
    case update
    case delete
}

public typealias OnChange<T> = ((T, ChangeType) -> Void)

open class SingleFetchedResultController<T: NSManagedObject> {
    public var predicate: NSPredicate
    public let managedObjectContext: NSManagedObjectContext
    public let onChange: OnChange<T>
    open fileprivate(set) var object: T? = nil

    public init(predicate: NSPredicate? = nil, managedObjectContext: NSManagedObjectContext, onChange: @escaping OnChange<T>) {
    
        self.predicate = predicate ?? NSPredicate()
        self.managedObjectContext = managedObjectContext
        self.onChange = onChange

        NotificationCenter.default.addObserver(self, selector: #selector(objectsDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    open func performFetch() throws {
        let fetchRequest = NSFetchRequest<T>(entityName: T.entityName())
        fetchRequest.predicate = predicate

        let results = try managedObjectContext.fetch(fetchRequest)
        assert(results.count < 2) // we shouldn't have any duplicates

        if let result = results.first {
            object = result
            onChange(result, .firstFetch)
        }
    }

    @objc func objectsDidChange(_ notification: Notification) {
        updateCurrentObject(notification: notification, key: NSInsertedObjectsKey)
        updateCurrentObject(notification: notification, key: NSUpdatedObjectsKey)
        updateCurrentObject(notification: notification, key: NSDeletedObjectsKey)
    }

    fileprivate func updateCurrentObject(notification: Notification, key: String) {
        guard let allModifiedObjects = (notification as NSNotification).userInfo?[key] as? Set<NSManagedObject> else {
            return
        }

        let objectsWithCorrectType = Set(allModifiedObjects.filter { return $0 as? T != nil })
        let matchingObjects = NSSet(set: objectsWithCorrectType)
            .filtered(using: self.predicate) as? Set<NSManagedObject> ?? []

        assert(matchingObjects.count < 2)

        guard let matchingObject = matchingObjects.first as? T else {
            return
        }

        object = matchingObject
        onChange(matchingObject, changeType(fromKey: key))
    }
    
    fileprivate func changeType(fromKey key: String) -> ChangeType {
        let map: [String : ChangeType] = [
            NSInsertedObjectsKey : .insert,
            NSUpdatedObjectsKey : .update,
            NSDeletedObjectsKey : .delete]
        
        return map[key]!
    }
}
