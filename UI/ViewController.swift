//
//  ViewController.swift
//  CoreDataMnager
//
//  Created by Sergey on 11/21/18.
//  Copyright © 2018 sblinov.com. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CoreDataManager.shared.save({
            _ = User.createEntity()?.name = "Super user"
            _ = Friend.createEntity()?.name = "Friend"
            
        }) { status in
            print(status)
            var users = [Entity]()
            users.append(contentsOf: User.all()!)
            users.append(contentsOf: Friend.all()!)
            for user in users {
                print(user.descriptionName)
            }
        }
    }
}

