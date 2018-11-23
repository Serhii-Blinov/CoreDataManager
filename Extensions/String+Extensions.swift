//
//  String+Extensions.swift
//  CoreDataManager
//
//  Created by Sergey on 11/23/18.
//  Copyright © 2018 sblinov.com. All rights reserved.
//

import Foundation

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

extension String {
    func toDate() -> Date? {
        let formater = DateFormatter()
        formater.dateFormat = "yyyyMMddss"
        return formater.date(from: self)
    }
}
