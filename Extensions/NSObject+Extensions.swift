//  Repos
//
//  Created by Sergey on 6/10/18.
//  Copyright © 2018 Sergey Blinov. All rights reserved.
//

import Foundation

public extension NSObject {
    
    var className: String {
        return NSStringFromClass(type(of: self))
    }
    
    public class var className: String {
        return NSStringFromClass(self).components(separatedBy: ".").last ?? ""
    }
}
