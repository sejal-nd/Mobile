//
//  UserSession.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/18/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

class UserSession {
//    enum State {
//        case loggedIn
//        case loggedOut
//    }
//
//    var state: State {
//        if token.isEmpty {
//            return .loggedOut
//        } else {
//            return .loggedIn
//        }
//    }
    
    static let shared = UserSession()
    
    private init() {
        
    }


    
    var token = ""

    
    var refreshDate = Date()
    
    
    
    
}


enum TestUserSession {
    
    static var token: String {
        return ""
    }
    
    private static var refreshDate: Date {
        return Date()
    }
    
    static var isRefreshTokenExpired: Bool {
        return Date() > TestUserSession.refreshDate
    }
}
