//
//  GameUser.swift
//  Mobile
//
//  Created by Cody Dillon on 6/10/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct GameUser: Decodable {
    var onboardingComplete: Bool
    var optedOut: Bool
    var points: Double
    var taskIndex: Int
    let pilotGroup: String?
    let cluster: String?
    let onboardingRentOrOwnAnswer: String?
    
    enum CodingKeys: String, CodingKey {
        case onboardingComplete
        case optedOut
        case points
        case taskIndex
        case pilotGroup
        case cluster
        case onboardingRentOrOwnAnswer
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
                
        if let onboardingCompleteStr: String = try container.decodeIfPresent(String.self, forKey: .onboardingComplete) {
            onboardingComplete = onboardingCompleteStr.lowercased() == "true"
        } else {
            onboardingComplete = false
        }
        
        if let optedOutStr: String = try container.decodeIfPresent(String.self, forKey: .optedOut) {
            optedOut = optedOutStr.lowercased() == "true"
        } else {
            optedOut = false
        }
        
        if let pointsStr: String = try container.decodeIfPresent(String.self, forKey: .points) {
            points = Double(pointsStr) ?? 0
        } else {
            points = 0
        }
        
        if let taskIndexStr: String = try container.decodeIfPresent(String.self, forKey: .taskIndex) {
            taskIndex = Int(taskIndexStr) ?? 0
        } else {
            taskIndex = 0
        }
        
        pilotGroup = try container.decode(String.self, forKey: .pilotGroup)
        cluster = try container.decode(String.self, forKey: .cluster)
        onboardingRentOrOwnAnswer = try container.decode(String.self, forKey: .onboardingRentOrOwnAnswer)
    }
}
