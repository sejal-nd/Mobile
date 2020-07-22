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
    var points: Double
    var taskIndex: Int
    let pilotGroup: String?
    let cluster: String?
    let onboardingRentOrOwnAnswer: String?
        
    init(map: Mapper) throws {
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
            points = Double(pointsStr) ?? 0
        } else {
            points = 0
        }
        
        if let taskIndexStr: String = map.optionalFrom("taskIndex") {
            taskIndex = Int(taskIndexStr) ?? 0
        } else {
            taskIndex = 0
        }
        
        pilotGroup = map.optionalFrom("pilotGroup")
        cluster = map.optionalFrom("cluster")
        onboardingRentOrOwnAnswer = map.optionalFrom("onboardingRentOrOwnAnswer")
    }
    
    init(onboardingComplete: Bool, optedOut: Bool, points: Double, taskIndex: Int) {
        if Environment.shared.environmentName != .aut {
            fatalError("init only available for tests")
        }
        
        var map = [String: Any]()
        map["onboardingComplete"] = onboardingComplete ? "true" : "false"
        map["optedOut"] = optedOut ? "true" : "false"
        map["points"] = String(points)
        map["taskIndex"] = String(taskIndex)
        self = GameUser.from(map as NSDictionary)!
    }

}
