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

    var inventoryTitle: String {
        switch self {
        case .background:
            return "Backgrounds"
        case .hat:
            return "Hats"
        case .accessory:
            return "Accessories"
        }
    }
}

struct Gift {
    let id: String
    let type: GiftType
    let requiredPoints: Int
    let thumbImage: UIImage
    let dayImage: UIImage?
    let nightImage: UIImage?
    let image: UIImage?
}

class GiftInventory {

    static let shared = GiftInventory()

    private let inventory: [Gift] = [
        Gift(id: "bg_bay", type: .background, requiredPoints: 0, thumbImage: UIImage(named: "bay_thumb")!, dayImage: UIImage(named: "bay_bg_day")!, nightImage: UIImage(named: "bay_bg_night")!, image: nil),
        Gift(id: "bg_falltrees", type: .background, requiredPoints: 16, thumbImage: UIImage(named: "falltrees_thumb")!, dayImage: UIImage(named: "falltrees_bg_day")!, nightImage: UIImage(named: "falltrees_bg_night")!, image: nil),
        Gift(id: "bg_farm", type: .background, requiredPoints: 32, thumbImage: UIImage(named: "farm_thumb")!, dayImage: UIImage(named: "farm_bg_day")!, nightImage: UIImage(named: "farm_bg_night")!, image: nil),
        Gift(id: "bg_forest", type: .background, requiredPoints: 48, thumbImage: UIImage(named: "forest_thumb")!, dayImage: UIImage(named: "forest_bg_day")!, nightImage: UIImage(named: "forest_bg_night")!, image: nil),
        Gift(id: "bg_mdresidential", type: .background, requiredPoints: 64, thumbImage: UIImage(named: "mdresidential_thumb")!, dayImage: UIImage(named: "mdresidential_bg_day")!, nightImage: UIImage(named: "mdresidential_bg_night")!, image: nil),
        Gift(id: "bg_skipjack", type: .background, requiredPoints: 80, thumbImage: UIImage(named: "skipjack_thumb")!, dayImage: UIImage(named: "skipjack_bg_day")!, nightImage: UIImage(named: "skipjack_bg_night")!, image: nil),
        Gift(id: "bg_snow", type: .background, requiredPoints: 96, thumbImage: UIImage(named: "snow_thumb")!, dayImage: UIImage(named: "snow_bg_day")!, nightImage: UIImage(named: "snow_bg_night")!, image: nil),
        Gift(id: "bg_susans", type: .background, requiredPoints: 112, thumbImage: UIImage(named: "susans_thumb")!, dayImage: UIImage(named: "susans_bg_day")!, nightImage: UIImage(named: "susans_bg_night")!, image: nil),
    ]
    
    func giftUnlockedWhen(pointsBefore: Int, pointsAfter: Int) -> Gift? {
        let giftsUnlockedBefore = inventory.filter { pointsBefore >= $0.requiredPoints }
        let giftsUnlockedAfter = inventory.filter { pointsAfter >= $0.requiredPoints }
        if giftsUnlockedAfter.count > giftsUnlockedBefore.count {
            return giftsUnlockedAfter.last
        }
        return nil
    }
    
    func gifts(ofType type: GiftType) -> [Gift] {
        return inventory.filter { $0.type == type }
    }

}
