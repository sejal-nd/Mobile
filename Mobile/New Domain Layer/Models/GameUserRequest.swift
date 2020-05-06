//
//  GameUserRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 5/5/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct GameUserRequest: Encodable {
    let onboardingComplete: Bool
    let optedOut: Bool
    let points: Double
    let taskIndex: Int
    let pilotGroup: String?
    let cluster: String?
    let onboardingRentOrOwnAnswer: String?
}
