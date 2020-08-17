//
//  GameTask.swift
//  Mobile
//
//  Created by Marc Shilling on 12/4/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation

struct GameTask: Decodable {
    let type: GameTaskType
    let tip: GameTip?
    let quiz: GameQuiz?
    let survey: GameSurvey?
}
