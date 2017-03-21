//
//  Environment.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

/// Convenience singleton that wraps environment variables.
struct Environment  {
    
    static let sharedInstance = Environment()
    
    let environmentName: String
    let appName: String
    let opco: String
    let oAuthEndpoint: String
    
    private init() {
        let path = Bundle.main.path(forResource: "environment", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path!)
    
        environmentName = dict?["environment"] as! String
        appName = dict?["appName"] as! String
        opco = dict?["opco"] as! String
        oAuthEndpoint = dict?["oauthEndpoint"] as! String
    }
    
    var opcoDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        switch opco {
        case "BGE":
            formatter.dateFormat = "MM/dd/yyyy hh:mm a"
            break
        case "ComEd":
            formatter.dateFormat = "hh:mm a 'on' MM/dd/yyyy"
            break
        case "PECO":
            formatter.dateFormat = "h:mm a zz 'on' MM/dd/yyyy"
            break
        default:
            formatter.dateFormat = "h:mm a MM/dd/yy"
            break
        }
        return formatter
    }
}
