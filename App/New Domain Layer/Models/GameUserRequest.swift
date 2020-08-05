//
//  GameUserRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 5/5/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct GameUserRequest: Encodable {
    var onboardingComplete: String? = nil
    var optedOut: String? = nil
    var points: String? = nil
    var taskIndex: String? = nil
    var pilotGroup: String? = nil
    var cluster: String? = nil
    var onboardingRentOrOwnAnswer: String? = nil
    var checkInHowDoYouFeelAnswer: String? = nil
    var lastLogin: String? = nil
    
    // Gift Selections
    var selectedBackground: String? = nil
    var selectedHat: String? = nil
    var selectedAccessory: String? = nil
    
    var initialEBillEnrollment: String? = nil
    var initialHomeProfile: String? = nil
    
    var pilotEBillEnrollment: String? = nil
    var pilotHomeProfileCompletion: String? = nil
    
    init(gameUser: GameUser) {
        self.onboardingComplete = String(gameUser.onboardingComplete)
        self.optedOut = String(gameUser.optedOut)
        self.points = String(gameUser.points)
        self.taskIndex = String(gameUser.taskIndex)
        self.pilotGroup = gameUser.pilotGroup
        self.cluster = gameUser.cluster
        self.onboardingRentOrOwnAnswer = gameUser.onboardingRentOrOwnAnswer
    }
    
    public init(onboardingComplete: String? = nil, optedOut: String? = nil, points: String? = nil, taskIndex: String? = nil, pilotGroup: String? = nil, cluster: String? = nil, onboardingRentOrOwnAnswer: String? = nil, checkInHowDoYouFeelAnswer: String? = nil, lastLogin: String? = nil, selectedBackground: String? = nil, selectedHat: String? = nil, selectedAccessory: String? = nil, initialEBillEnrollment: String? = nil, initialHomeProfile: String? = nil, pilotEBillEnrollment: String? = nil, pilotHomeProfileCompletion: String? = nil) {
        self.onboardingComplete = onboardingComplete
        self.optedOut = optedOut
        self.points = points
        self.taskIndex = taskIndex
        self.pilotGroup = pilotGroup
        self.cluster = cluster
        self.onboardingRentOrOwnAnswer = onboardingRentOrOwnAnswer
        self.checkInHowDoYouFeelAnswer = checkInHowDoYouFeelAnswer
        self.lastLogin = lastLogin
        self.selectedBackground = selectedBackground
        self.selectedHat = selectedHat
        self.selectedAccessory = selectedAccessory
        self.initialEBillEnrollment = initialEBillEnrollment
        self.initialHomeProfile = initialHomeProfile
        self.pilotEBillEnrollment = pilotEBillEnrollment
        self.pilotHomeProfileCompletion = pilotHomeProfileCompletion
    }
}
