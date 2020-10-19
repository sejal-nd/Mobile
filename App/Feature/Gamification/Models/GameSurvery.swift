//
//  GameSurvery.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/17/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

// For the pilot, we have two different surveys and we space them out in the task list,
// prompting users who select "Remind Me Later" up to 3 times.
struct GameSurvey: Decodable {
    let surveyNumber: Int
    let attempt: Int
}
