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
        Gift(id: "bg_bay", type: .background, requiredPoints: 0, thumbImage: UIImage(named: "bg_bay_thumb")!, dayImage: UIImage(named: "bg_bay_day")!, nightImage: UIImage(named: "bg_bay_night")!, image: nil),
        Gift(id: "bg_falltrees", type: .background, requiredPoints: 16, thumbImage: UIImage(named: "bg_falltrees_thumb")!, dayImage: UIImage(named: "bg_falltrees_day")!, nightImage: UIImage(named: "bg_falltrees_night")!, image: nil),
        Gift(id: "bg_farm", type: .background, requiredPoints: 32, thumbImage: UIImage(named: "bg_farm_thumb")!, dayImage: UIImage(named: "bg_farm_day")!, nightImage: UIImage(named: "bg_farm_night")!, image: nil),
        Gift(id: "bg_forest", type: .background, requiredPoints: 48, thumbImage: UIImage(named: "bg_forest_thumb")!, dayImage: UIImage(named: "bg_forest_day")!, nightImage: UIImage(named: "bg_forest_night")!, image: nil),
        Gift(id: "bg_mdresidential", type: .background, requiredPoints: 64, thumbImage: UIImage(named: "bg_mdresidential_thumb")!, dayImage: UIImage(named: "bg_mdresidential_day")!, nightImage: UIImage(named: "bg_mdresidential_night")!, image: nil),
        Gift(id: "bg_skipjack", type: .background, requiredPoints: 80, thumbImage: UIImage(named: "bg_skipjack_thumb")!, dayImage: UIImage(named: "bg_skipjack_day")!, nightImage: UIImage(named: "bg_skipjack_night")!, image: nil),
        Gift(id: "bg_snow", type: .background, requiredPoints: 96, thumbImage: UIImage(named: "bg_snow_thumb")!, dayImage: UIImage(named: "bg_snow_day")!, nightImage: UIImage(named: "bg_snow_night")!, image: nil),
        Gift(id: "bg_susans", type: .background, requiredPoints: 112, thumbImage: UIImage(named: "bg_susans_thumb")!, dayImage: UIImage(named: "bg_susans_day")!, nightImage: UIImage(named: "bg_susans_night")!, image: nil),
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
    
    func gift(withId id: String) -> Gift? {
        return inventory.first { $0.id == id }
    }
    
    /* Audits the selected gifts in UserDefaults and ensures they should be unlocked for the passed
     * in point value. In the real world, this is likely unnecessary. If point total is manually
     * adjusted by dev/QA, or if the user logs into multiple gamification accounts, it resolves the
     * issue of a locked item being selected.
     */
    func auditUserDefaults(userPoints: Int) {
        if let selectedBgId = UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedBackground),
            let selectedBg = GiftInventory.shared.gift(withId: selectedBgId),
            selectedBg.requiredPoints > userPoints {
            UserDefaults.standard.set(nil, forKey: UserDefaultKeys.gameSelectedBackground)
        }
        
        if let selectedHatId = UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedHat),
            let selectedHat = GiftInventory.shared.gift(withId: selectedHatId),
            selectedHat.requiredPoints > userPoints {
            UserDefaults.standard.set(nil, forKey: UserDefaultKeys.gameSelectedHat)
        }
        
        if let selectedAccessoryId = UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedAccessory),
            let selectedAccessory = GiftInventory.shared.gift(withId: selectedAccessoryId),
            selectedAccessory.requiredPoints > userPoints {
            UserDefaults.standard.set(nil, forKey: UserDefaultKeys.gameSelectedAccessory)
        }
    }

}
