//
//  Date+Extensions.swift
//  CoreDataManager
//
//  Created by Sergey on 11/23/18.
//  Copyright © 2018 sblinov.com. All rights reserved.
//

import Foundation

extension Date {
    func toString() -> String {
        let formater = DateFormatter()
        formater.dateFormat = "yyyyMMddss"
        return formater.string(from: self)
    }
}
