//
//  PushNotification.swift
//  Mobile
//
//  Created by Marc Shilling on 11/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class PushNotification: NSObject, NSCoding {
    
    struct Keys {
        static let accountNumbers = "pnAccountNumbers"
        static let title = "pnTitle"
        static let message = "pnMessage"
        static let date = "pnDate"
    }
    
    var accountNumbers: [String]
    var title: String?
    var message: String?
    var date: Date
    
    init(accountNumbers: [String], title: String?, message: String?, date: Date = Date()) {
        self.accountNumbers = accountNumbers
        self.title = title
        self.message = message
        self.date = date
    }
    
    required init?(coder aDecoder: NSCoder) {
        if let accountNumbersObj = aDecoder.decodeObject(forKey: Keys.accountNumbers) as? [String] {
            self.accountNumbers = accountNumbersObj
        } else {
            self.accountNumbers = [String]()
        }
        
        if let titleObj = aDecoder.decodeObject(forKey: Keys.title) as? String {
            self.title = titleObj
        }
        
        if let messageObj = aDecoder.decodeObject(forKey: Keys.message) as? String {
            self.message = messageObj
        }
        
        self.date = aDecoder.decodeObject(forKey: Keys.date) as! Date
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.accountNumbers, forKey: Keys.accountNumbers)
        aCoder.encode(self.title, forKey: Keys.title)
        aCoder.encode(self.message, forKey: Keys.message)
        aCoder.encode(self.date, forKey: Keys.date)
    }
}
