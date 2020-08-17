//
//  GameTip.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/17/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct GameTip: Decodable {
    let id: String
    let title: String
    let description: String
    let numPeople: Int?
    let savingsPerYear: Int?
    let serviceType: String // Not used for pilot
    let rentOrOwn: String
    let season: String?
}
