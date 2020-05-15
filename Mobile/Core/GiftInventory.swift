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
    let requiredPoints: Double
    let customMessage: String?
    
    init(id: String, type: GiftType, requiredPoints: Double, customMessage: String? = nil) {
        self.id = id
        self.type = type
        self.requiredPoints = requiredPoints
        self.customMessage = customMessage
    }
    
    // All gifts should have a thumbImage
    var thumbImage: UIImage? {
        UIImage(named: "\(id)_thumb")
    }
    
    // Backgrounds only
    var dayImage: UIImage? {
        UIImage(named: "\(id)_day")
    }
    
    // Backgrounds only
    var nightImage: UIImage? {
        UIImage(named: "\(id)_night")
    }
    
    // Hats + Accessories only
    var image: UIImage? {
        UIImage(named: id)
    }
}

extension Gift: Equatable {
    static func == (lhs: Gift, rhs: Gift) -> Bool {
        return lhs.id == rhs.id
    }
}

class GiftInventory {

    static let shared = GiftInventory()
    
    private let orderedAssetIds = [
        "bg_bay", "hat_maryland", "hat_beaniegreen", "acc_hornrimmed", "bg_mdresidential",
        "hat_bgehardhat", "acc_safetyglasses", "bg_cherryblossoms", "hat_sprout", "hat_flowercrown",
        "acc_cateye", "bg_skipjack", "hat_crab", "acc_sunglasses", "hat_sailor", "bg_susans",
        "hat_sunhat", "hat_fancy", "hat_beretred", "acc_glasses", "bg_forest", "hat_oriole",
        "hat_dog", "hat_cat", "bg_farm", "hat_strawhat", "hat_horse", "hat_rodent", "hat_rabbit",
        "bg_baltimoreharbor", "hat_beaniefootball", "hat_capbaseball", "bg_ellicottcity",
        "hat_tophat", "acc_monocle", "hat_bow", "hat_capgreen", "hat_stripedbow", "bg_colonialmd",
        "hat_colonial", "hat_cowboy", "bg_falltrees", "hat_ghost", "hat_beretblack", "hat_paper",
        "bg_space", "hat_ecocrown"
    ]
    
    private let customMessages = [
        "hat_bgehardhat": "Safety first!",
        "hat_dog": "Woof!",
        "hat_cat": "Meow!",
        "hat_horse": "Neigh!",
        "hat_capbaseball": "Play ball!",
        "hat_colonial": "How do you do?",
        "hat_cowboy": "Howdy!",
        "hat_ghost": "Boo!"
    ]
    
    private let inventory: [Gift]!
    
    init() {
        var inventory = [Gift]()
        
        var requiredPoints: Double = 16
        for id in orderedAssetIds {
            let type: GiftType
            switch id.split(separator: "_").first {
            case "bg":
                type = .background
            case "hat":
                type = .hat
            case "acc":
                type = .accessory
            default:
                fatalError("Could not map GiftType")
            }
            
            inventory.append(Gift(id: id, type: type, requiredPoints: requiredPoints, customMessage: customMessages[id]))
                
            requiredPoints += 16
        }
        
        self.inventory = inventory
    }
    
    func numGiftsUnlocked(forPointValue points: Double) -> Int {
        return inventory.filter { points >= $0.requiredPoints }.count
    }
    
    func lastUnlockedGift(forPointValue points: Double) -> Gift? {
        let unlockedGifts = inventory.filter { points >= $0.requiredPoints }
        return unlockedGifts.last
    }
    
    func gifts(ofType type: GiftType) -> [Gift] {
        return inventory.filter { $0.type == type }
    }
    
    func gift(withId id: String) -> Gift? {
        return inventory.first { $0.id == id }
    }
    
    func isFinalGift(gift: Gift) -> Bool {
        if let lastGift = inventory.last, lastGift == gift {
            return true
        }
        return false
    }
    
    /* Audits the selected gifts in UserDefaults and ensures they should be unlocked for the passed
     * in point value. In the real world, this is likely unnecessary. If point total is manually
     * adjusted by dev/QA, or if the user logs into multiple gamification accounts, it resolves the
     * issue of a locked item being selected.
     */
    func auditUserDefaults(userPoints: Double) {
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
