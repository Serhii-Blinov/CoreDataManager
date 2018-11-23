//
//  Value.swift
//  CoreDataManager
//
//  Created by Sergey on 11/22/18.
//  Copyright © 2018 sblinov.com. All rights reserved.
//

import Foundation

class DateEncryptionTransformer: EncryptionTransformer {
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let date = value as? Date else { return nil }
        return super.transformedValue(date.stringlize())
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any?{
        guard let data = value as? Data,
            let string = super.reverseTransformedValue(data) as? String else { return nil }
        
        return string .datelize()
    }
}

class EncryptionTransformer: ValueTransformer {
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let string = value as? String,
            let data = string.data(using: .utf8) else { return nil }
        do {
            let encryptData = try self.encryptor?.encrypt(data) as Any?
            return encryptData
        } catch {
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any?{
        guard let data = value as? Data else { return nil }
        do {
            guard let decrypData = try self.encryptor?.decrypt(data) else { return nil }
            
            return String(data: decrypData, encoding: .utf8)
            
        } catch {
            return nil
        }
    }
    
    lazy var encryptor: AES256Crypter? = {
        return try? AES256Crypter.init(key: self.key, iv: self.iv)
    }()
    
    lazy var key: Data = {
        return "12345678912345671234567891234567".data(using: .utf8)! //TODO: put it to keychain
    }()
    
    lazy var iv: Data = {
        return "1234567891234567".data(using: .utf8)!  //TODO: put it to keychain
    }()
}

extension Date {
    func stringlize() -> String {
        let formater = DateFormatter()
        formater.dateFormat = "yyyyMMddss"
        return formater.string(from: self)
    }
}

extension String {
    func datelize() -> Date? {
        let formater = DateFormatter()
        formater.dateFormat = "yyyyMMddss"
        return formater.date(from: self)
    }
}
