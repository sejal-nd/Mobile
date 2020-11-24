//
//  GameTaskType.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/17/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

enum GameTaskType: String, Decodable {
    case tip = "tip"
    case quiz = "quiz"
    case fab = "fab"
    case eBill = "ebill"
    case homeProfile = "homeprofile"
    case survey = "survey"
    case checkIn = "checkin"
    case onboarding = "onboarding"
}
