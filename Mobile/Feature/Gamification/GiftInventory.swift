//
//  GiftInventory.swift
//  Mobile
//
//  Created by Marc Shilling on 12/5/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation

enum GiftType: String {
    case background, hat, accessory
}

struct Gift {
    let type: GiftType
    let backgroundImage: UIImage?
    let lottieFileName: String?
    let requiredPoints: Int
}
    
class GiftInventory {

    static let shared = GiftInventory()

    private let inventory = [
        Gift(type: .background, backgroundImage: nil, lottieFileName: nil, requiredPoints: 16)
    ]
    
    func giftUnlockedWhen(pointsBefore: Int, pointsAfter: Int) -> Gift? {
        let giftsUnlockedBefore = inventory.filter { pointsBefore >= $0.requiredPoints }
        let giftsUnlockedAfter = inventory.filter { pointsAfter >= $0.requiredPoints }
        if giftsUnlockedAfter.count > giftsUnlockedBefore.count {
            return giftsUnlockedAfter.last
        }
        return nil
    }
    
}
