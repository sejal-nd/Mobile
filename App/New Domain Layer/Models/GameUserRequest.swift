//
//  GameUserRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 5/5/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct GameUserRequest: Encodable {
    var onboardingComplete: String?
    var optedOut: String?
    var points: String?
    var taskIndex: String?
    var pilotGroup: String?
    var cluster: String?
    var onboardingRentOrOwnAnswer: String?
    var checkInHowDoYouFeelAnswer: String?
    var lastLogin: String?
    
    // Gift Selections
    var selectedBackground: String?
    var selectedHat: String?
    var selectedAccessory: String?
    
    init() {
        
    }
    
    init(gameUser: NewGameUser) {
        self.onboardingComplete = String(gameUser.onboardingComplete)
        self.optedOut = String(gameUser.optedOut)
        self.points = String(gameUser.points)
        self.taskIndex = String(gameUser.taskIndex)
        self.pilotGroup = gameUser.pilotGroup
        self.cluster = gameUser.cluster
        self.onboardingRentOrOwnAnswer = gameUser.onboardingRentOrOwnAnswer
    }
}
