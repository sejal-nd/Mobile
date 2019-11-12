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
        
    init(map: Mapper) throws {
        onboardingComplete = map.optionalFrom("onboardingComplete") ?? false
        optedOut = map.optionalFrom("optedOut") ?? false
        try points = map.from("points")
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
