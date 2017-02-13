//
//  Environment.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

struct Environment  {
    
    static let sharedInstance = Environment()
    
    let environmentName: String
    let appName: String
    
    private init() {
        
        let path = Bundle.main.path(forResource: "environment", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path!)
    
        environmentName = dict?["environment"] as! String
        appName = dict?["appName"] as! String
    }
}
