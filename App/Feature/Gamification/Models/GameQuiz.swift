//
//  GameQuiz.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/17/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct GameQuiz: Decodable {
    let question: String
    let answers: [Answer]
    let answerDescription: String
    let serviceType: String // Not used for pilot
    let rentOrOwn: String
    let season: String?
    let tipId: String?
    
    struct Answer: Decodable {
        let value: String
        let isCorrect: Bool
        
        enum CodingKeys: String, CodingKey {
            case value = "answer"
            case isCorrect = "correct"
        }
    }
}
