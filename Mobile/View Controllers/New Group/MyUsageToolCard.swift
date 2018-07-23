//
//  MyUsageToolCard.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/20/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

struct MyUsageToolCard: Equatable {
    let image: UIImage?
    let title: String
    
    static func == (lhs: MyUsageToolCard, rhs: MyUsageToolCard) -> Bool {
        return lhs.image == rhs.image && lhs.title == rhs.title
    }
}
