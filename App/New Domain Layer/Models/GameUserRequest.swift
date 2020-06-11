//
//  GameUserRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 5/5/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct GameUserRequest: Encodable {
    let onboardingComplete: String
    let optedOut: String
    let points: String
    let taskIndex: String
    let pilotGroup: String?
    let cluster: String?
    let onboardingRentOrOwnAnswer: String?
    
    init(gameUser: NewGameUser) {
        self.init(onboardingComplete: gameUser.onboardingComplete, optedOut: gameUser.optedOut, points: gameUser.points, taskIndex: gameUser.taskIndex, pilotGroup: gameUser.pilotGroup, cluster: gameUser.cluster, onboardingRentOrOwnAnswer: gameUser.onboardingRentOrOwnAnswer)
    }
    
    init(onboardingComplete: Bool, optedOut: Bool, points: Double, taskIndex: Int, pilotGroup: String?, cluster: String?, onboardingRentOrOwnAnswer: String?) {
        self.onboardingComplete = String(onboardingComplete)
        self.optedOut = String(optedOut)
        self.points = String(points)
        self.taskIndex = String(taskIndex)
        self.pilotGroup = pilotGroup
        self.cluster = cluster
        self.onboardingRentOrOwnAnswer = onboardingRentOrOwnAnswer
    }
}
