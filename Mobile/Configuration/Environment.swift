//
//  Environment.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

enum OpCo: String {
    case bge = "BGE"
    case comEd = "ComEd"
    case peco = "PECO"
    
    var displayString: String {
        return rawValue
    }
}

/// Convenience singleton that wraps environment variables.
struct Environment  {
    
    static let sharedInstance = Environment()
    
    let environmentName: String
    let appName: String
    let opco: OpCo
    let oAuthEndpoint: String
    let mcsInstanceName: String
    let fiservUrl: String
    let outageMapUrl: String
    let gaTrackingId: String
    let firebaseConfigFile: String
    
    private init() {
        let path = Bundle.main.path(forResource: "environment", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path!)
    
        environmentName = dict?["environment"] as! String
        appName = dict?["appName"] as! String
        opco = OpCo(rawValue: dict?["opco"] as! String)!
        oAuthEndpoint = dict?["oauthEndpoint"] as! String
        mcsInstanceName = dict?["mcsInstanceName"] as! String
        fiservUrl = dict?["fiservUrl"] as! String
        outageMapUrl = dict?["outageMapUrl"] as! String
        gaTrackingId = dict?["gaTrackingId"] as! String
        firebaseConfigFile = dict?["firebaseConfigFile"] as! String
    }
    
    var opcoDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        switch opco {
        case .bge:
            formatter.dateFormat = "MM/dd/yyyy hh:mm a"
        case .comEd:
            formatter.dateFormat = "hh:mm a 'on' M/dd/yyyy"
        case .peco:
            formatter.dateFormat = "h:mm a zz 'on' M/dd/yyyy"
        }
        return formatter
    }
}
