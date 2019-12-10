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
}

struct GameTask: Mappable {
    
    let type: GameTaskType
    let tip: GameTip?
    let quiz: GameQuiz?

    init(map: Mapper) throws {
        type = try map.from("type")
        tip = map.optionalFrom("tip")
        quiz = map.optionalFrom("quiz")
    }
    
}

struct GameTip: Mappable {
    
    let id: String
    let title: String
    let description: String
    let numPeople: Int
    let savingsPerYear: Double
    let serviceType: String
    let rentOrOwn: String
    
    init(map: Mapper) throws {
        id = try map.from("id")
        title = try map.from("title")
        description = try map.from("description")
        numPeople = try map.from("numPeople")
        savingsPerYear = try map.from("savingsPerYear")
        serviceType = try map.from("serviceType")
        rentOrOwn = try map.from("rentOrOwn")
    }
    
//    // For temp testing only
//    init(title: String, description: String) {
//        var map = [String: Any]()
//        map["id"] = "1234"
//        map["title"] = title
//        map["description"] = description
//        map["numPeople"] = 1000
//        map["savingsPerYear"] = 30
//        map["serviceType"] = "GAS/ELECTRIC"
//        map["rentOrOwn"] = "RENT"
//        self = GameTip.from(map as NSDictionary)!
//    }
}

struct GameQuiz: Mappable {
    
    let question: String
    let answers: [(String, Bool)]
    let answerDescription: String
    let serviceType: String
    let rentOrOwn: String
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
        tipId = map.optionalFrom("tipId")
    }
    
//    // For temp testing only
//    init(question: String, answers: [[String: Any]], answerDescription: String) {
//        var map = [String: Any]()
//        map["question"] = question
//        map["answers"] = answers
//        map["answerDescription"] = answerDescription
//        map["serviceType"] = "GAS/ELECTRIC"
//        map["rentOrOwn"] = "RENT"
//        map["tipId"] = "1234"
//        self = GameQuiz.from(map as NSDictionary)!
//    }
}
