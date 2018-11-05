//
//  UserDefaults+isFirstLaunch.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/20/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

//import Foundation
//
//extension UserDefaults {
//    
//    // check for is first launch - only true on first invocation after app install, false on all further invocations
//    // Note: Store this value in AppDelegate if you have multiple places where you are checking for this flag
//    static func isFirstLaunch() -> Bool {
//        let hasBeenLaunchedBeforeFlag = "hasBeenLaunchedBeforeFlag234"
//        let isFirstLaunch = !UserDefaults.standard.bool(forKey: hasBeenLaunchedBeforeFlag)
//        if isFirstLaunch {
//            UserDefaults.standard.set(true, forKey: hasBeenLaunchedBeforeFlag)
//        }
//        return isFirstLaunch
//    }
//    
//}
