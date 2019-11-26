//
//  GameUser.swift
//  Mobile
//
//  Created by Marc Shilling on 11/12/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

struct GameUser: Mappable {
    var onboardingComplete: Bool
    var optedOut: Bool
    var points: Int
    var isClusterTwo: Bool
    let pilotGroup: String?
        
    init(map: Mapper) throws {
//        onboardingComplete = map.optionalFrom("onboardingComplete") ?? false
//        optedOut = map.optionalFrom("optedOut") ?? false
//
//        let pointStr: String? = map.optionalFrom("points")
//        if pointStr != nil, let pointInt = Int(pointStr!) {
//            points = pointInt
//        } else {
//            points = 0
//        }
        
        if let onboardingCompleteStr: String = map.optionalFrom("onboardingComplete") {
            onboardingComplete = onboardingCompleteStr.lowercased() == "true"
        } else {
            onboardingComplete = false
        }
        
        if let optedOutStr: String = map.optionalFrom("optedOut") {
            optedOut = optedOutStr.lowercased() == "true"
        } else {
            optedOut = false
        }
        
        if let pointsStr: String = map.optionalFrom("points") {
            points = Int(pointsStr) ?? 0
        } else {
            points = 0
        }
        
        if let isClusterTwoStr: String = map.optionalFrom("isClusterTwo") {
            isClusterTwo = isClusterTwoStr.lowercased() == "true"
        } else {
            isClusterTwo = false
        }
        
        pilotGroup = map.optionalFrom("pilotGroup")
    }
    
    // For temp testing only
    init(onboardingComplete: Bool, optedOut: Bool, points: Int) {
        var map = [String: Any]()
        map["onboardingComplete"] = onboardingComplete
        map["optedOut"] = optedOut
        map["points"] = points
        self = GameUser.from(map as NSDictionary)!
    }

}
