//
//  CoreDataManager.swift
//  CoreDataMnager
//
//  Created by Sergey on 11/21/18.
//  Copyright © 2018 sblinov.com. All rights reserved.
//

import Foundation
import CoreData

enum SaveStatus {
    case saved
    case rolledBack
    case noChanges
}

protocol StoreManager {
    var privateContext: NSManagedObjectContext { get }
    var mainContext: NSManagedObjectContext { get }
    
    func save(_ block:(()-> Void)?, completion:((SaveStatus)-> Void)?)
}

class CoreDataManager: StoreManager {
    
    static var shared = CoreDataManager()
    
    var privateContext: NSManagedObjectContext {
        return privateWriterContext
    }
    
    var mainContext: NSManagedObjectContext {
        return mainObjectContext
    }
    
    /* block will be execute on background Thread, completion on Main */
    func save(_ block:(()-> Void)? = nil, completion:((SaveStatus)-> Void)? = nil) {
        DispatchQueue.global().async {[weak self] in
            guard let strongSelf = self else { return }
            block?()
            guard strongSelf.privateContext.hasChanges else {
                DispatchQueue.main.async {
                    completion?(.noChanges)
                }
                return
            }
            
            strongSelf.privateContext.perform {[weak self] in
                do {
                    try strongSelf.privateContext.save()
                    strongSelf.mainObjectContext.perform {[weak self] in
                        do {
                            try self?.mainObjectContext.save()
                            completion?(.saved)
                        } catch {
                            completion?(.rolledBack)
                            print("CoreData: Unresolved error \(error)")
                        }
                    }
                } catch {
                    completion?(.rolledBack)
                    print("CoreData: Unresolved error \(error)")
                }
            }
        }
    }
    
    private init() {}
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        do {
            return try NSPersistentStoreCoordinator.coordinator(name: "CoreDataModel")
        } catch {
            print("CoreData: Unresolved error \(error)")
        }
        return nil
    }()
    
    private lazy var privateWriterContext: NSManagedObjectContext = {
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.parent = self.mainContext
        
        return managedObjectContext
    }()
    
    private lazy var mainObjectContext: NSManagedObjectContext = {
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
     
        return managedObjectContext
    }()
}

extension NSPersistentStoreCoordinator {
    
    public enum CoordinatorError: Error {
        case modelFileNotFound
        case modelCreationError
        case storePathNotFound
    }
    
    static func coordinator(name: String) throws -> NSPersistentStoreCoordinator? {
        guard let modelURL = Bundle.main.url(forResource: name, withExtension: "momd") else {
            throw CoordinatorError.modelFileNotFound
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw CoordinatorError.modelCreationError
        }
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            throw CoordinatorError.storePathNotFound
        }
        
        do {
            let url = documents.appendingPathComponent(String(format: "%@.sqlite", name))
            let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                           NSPersistentStoreFileProtectionKey: FileProtectionType.complete,
                           NSInferMappingModelAutomaticallyOption: true] as [String : Any]
            
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
            try FileManager.default.setAttributes([FileAttributeKey.protectionKey : FileProtectionType.complete], ofItemAtPath: url.path)
        } catch {
            throw error
        }
        
        return coordinator
    }
}
