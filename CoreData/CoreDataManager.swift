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
    var modelName: String { get }
    var threadContext: NSManagedObjectContext { get }
    var privateContext: NSManagedObjectContext { get }
    
    func save(async: Bool, performBlock: (()-> Void)?, completion: ((SaveStatus)-> Void)?)
}

class CoreDataManager: StoreManager {
    
    public typealias CoreDataManagerCompletion = () -> ()
    
    static var shared = CoreDataManager()
    
    var modelName: String {
        return "CoreDataModel"
    }
    
    private init() { }
    
    var threadContext: NSManagedObjectContext {
        if Thread.current.isMainThread {
            return self.mainObjectContext
        } else {
            return self.privateWriterContext
        }
    }
    
    var privateContext: NSManagedObjectContext {
        return self.privateWriterContext
    }
    
    // MARK: - Initialization & Core Data Stack
    
    func initialize(completion: CoreDataManagerCompletion? = nil) {
        // Fetch Persistent Store Coordinator
        guard let persistentStoreCoordinator = self.persistentStoreCoordinator else {
            fatalError("Unable to Set Up Core Data Stack")
        }
        
        DispatchQueue.global().async {
            // Add Persistent Store
            self.addPersistentStore(to: persistentStoreCoordinator)
            
            // Invoke Completion On Main Queue
            DispatchQueue.main.async { completion?() }
        }
    }
    
    /* block will be execute on background Thread, completion on Main */
    func save(async: Bool = true, performBlock: (()-> Void)? = nil, completion: ((SaveStatus)-> Void)? = nil) {
        self.privateWriterContext.perform(async: async) { [weak self] in
            performBlock?()
            
            guard let self = self, self.privateWriterContext.hasChanges || self.mainObjectContext.hasChanges else {
                DispatchQueue.main.async {
                    completion?(.noChanges)
                }
                
                return
            }
            
            do {
                try self.privateWriterContext.save()
                
                self.mainObjectContext.perform(async: async) { [weak self] in
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
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        do {
            return try NSPersistentStoreCoordinator.coordinator(modelName: self.modelName)
        } catch {
            print("CoreData: Unresolved error \(error)")
        }
        return nil
    }()
    
    private lazy var privateWriterContext: NSManagedObjectContext = {
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.parent = self.mainObjectContext
        
        return managedObjectContext
    }()
    
    private lazy var mainObjectContext: NSManagedObjectContext = {
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        return managedObjectContext
    }()
    
    private func addPersistentStore(to persistentStoreCoordinator: NSPersistentStoreCoordinator) {
        // Helpers
        let fileManager = FileManager.default
        let storeName = "\(self.modelName).sqlite"
        
        let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let persistentStoreURL = documentsDirectoryURL.appendingPathComponent(storeName)
        
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                           NSPersistentStoreFileProtectionKey: FileProtectionType.complete,
                           NSInferMappingModelAutomaticallyOption: true] as [String : Any]
            
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                              configurationName: nil,
                                                              at: persistentStoreURL,
                                                              options: options)
            
            try fileManager.setAttributes([FileAttributeKey.protectionKey : FileProtectionType.complete],
                                          ofItemAtPath: persistentStoreURL.path)
            
        } catch {
            fatalError("Unable to Add Persistent Store")
        }
    }
}

extension NSPersistentStoreCoordinator {
    
    public enum CoordinatorError: Error {
        case modelFileNotFound
        case modelCreationError
        case storePathNotFound
    }
    
    static func coordinator(modelName: String) throws -> NSPersistentStoreCoordinator? {
        
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            throw CoordinatorError.modelFileNotFound
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw CoordinatorError.modelCreationError
        }
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        return coordinator
    }
}

extension NSManagedObjectContext {
    
    func perform(async: Bool = true, performBlock: @escaping (()-> Void)) {
        if async {
            self.perform(performBlock)
        } else {
            self.performAndWait(performBlock)
        }
    }
}
