//
//  ViewController.swift
//  CoreDataMnager
//
//  Created by Sergey on 11/21/18.
//  Copyright © 2018 sblinov.com. All rights reserved.
//

import UIKit
import CoreData

extension String {
    
    static func random(length: Int = 20) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }
        return randomString
    }
}

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        for user in  User.all()!{
            print(user.name)
            print(user.bdate)
        }
//        
        CoreDataManager.shared.save({
           let user = User.createEntity()
            user?.name = String.random()
            user?.bdate = Date()
    
//
        }) { status in

        }
    }
}

