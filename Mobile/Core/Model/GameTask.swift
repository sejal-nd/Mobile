//
//  GameTask.swift
//  Mobile
//
//  Created by Marc Shilling on 12/4/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

enum GameTaskType: String {
    case tip = "tip"
    case quiz = "quiz"
    case fab = "fab"
    case eBill = "ebill"
    case homeProfile = "homeprofile"
    case survey = "survey"
    case checkIn = "checkin"
}

struct GameTask: Mappable {
    
    let type: GameTaskType
    let tip: GameTip?
    let quiz: GameQuiz?
    let survey: GameSurvey?

    init(map: Mapper) throws {
        type = try map.from("type")
        tip = map.optionalFrom("tip")
        quiz = map.optionalFrom("quiz")
        survey = map.optionalFrom("survey")
    }
    
}

struct GameTip: Mappable {
    
    let id: String
    let title: String
    let description: String
    let numPeople: Int?
    let savingsPerYear: Int?
    let serviceType: String // Not used for pilot
    let rentOrOwn: String
    let season: String?
    
    init(map: Mapper) throws {
        id = try map.from("id")
        title = try map.from("title")
        description = try map.from("description")
        numPeople = map.optionalFrom("numPeople")
        savingsPerYear = map.optionalFrom("savingsPerYear")
        serviceType = try map.from("serviceType")
        rentOrOwn = try map.from("rentOrOwn")
        season = map.optionalFrom("season")
    }
    
}

struct GameQuiz: Mappable {
    
    let question: String
    let answers: [(String, Bool)]
    let answerDescription: String
    let serviceType: String // Not used for pilot
    let rentOrOwn: String
    let season: String?
    let tipId: String?
    
    init(map: Mapper) throws {
        question = try map.from("question")
        
        guard let answerArray: [NSDictionary] = map.optionalFrom("answers") else {
            throw MapperError.customError(field: "answers", message: "error parsing answers array")
        }
        var arrayBuilder = [(String, Bool)]()
        for obj in answerArray {
            guard let answer = obj["answer"] as? String, let correct = obj["correct"] as? Bool else {
                throw MapperError.customError(field: "answers", message: "error parsing answers array")
            }
            arrayBuilder.append((answer, correct))
        }
        answers = arrayBuilder
        
        answerDescription = try map.from("answerDescription")
        serviceType = try map.from("serviceType")
        rentOrOwn = try map.from("rentOrOwn")
        season = map.optionalFrom("season")
        tipId = map.optionalFrom("tipId")
    }
    
}

// For the pilot, we have two different surveys and we space them out in the task list,
// prompting users who select "Remind Me Later" up to 3 times.
struct GameSurvey: Mappable {
    
    let surveyNumber: Int
    let attempt: Int

    init(map: Mapper) throws {
        surveyNumber = try map.from("surveyNumber")
        attempt = try map.from("attempt")
    }
    
}
