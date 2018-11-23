//
//  User+CoreData.swift
//  CoreDataManager
//
//  Created by Sergey on 11/23/18.
//  Copyright © 2018 sblinov.com. All rights reserved.
//

import Foundation
import CoreData

@objc(User)
public class User: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }
    
    @NSManaged public var bdate: Date?
    @NSManaged public var name: String?
}
