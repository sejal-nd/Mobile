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

class GiftInventory {

    static let shared = GiftInventory()

    private let inventory: [Gift] = [
        Gift(id: "bg_bay", type: .background, requiredPoints: 16),
        Gift(id: "hat_maryland", type: .hat, requiredPoints: 32),
        Gift(id: "bg_snow", type: .background, requiredPoints: 48),
        Gift(id: "hat_antlers", type: .hat, requiredPoints: 64),
        Gift(id: "hat_beaniegreen", type: .hat, requiredPoints: 80),
        Gift(id: "acc_hornrimmed", type: .accessory, requiredPoints: 96),
        Gift(id: "bg_mdresidential", type: .background, requiredPoints: 112),
        Gift(id: "hat_bgehardhat", type: .hat, requiredPoints: 128, customMessage: "Safety first!"),
        Gift(id: "acc_safetyglasses", type: .accessory, requiredPoints: 144),
        Gift(id: "bg_cherryblossoms", type: .background, requiredPoints: 160),
        Gift(id: "hat_sprout", type: .hat, requiredPoints: 176),
        Gift(id: "hat_flowercrown", type: .hat, requiredPoints: 192),
        Gift(id: "acc_cateye", type: .accessory, requiredPoints: 208),
        Gift(id: "hat_antlers", type: .hat, requiredPoints: 224),
        Gift(id: "bg_skipjack", type: .background, requiredPoints: 240),
        Gift(id: "hat_antlers", type: .hat, requiredPoints: 256),
        Gift(id: "hat_crab", type: .hat, requiredPoints: 272),
        Gift(id: "acc_sunglasses", type: .accessory, requiredPoints: 288),
        Gift(id: "hat_sailor", type: .hat, requiredPoints: 304),
        Gift(id: "bg_susans", type: .background, requiredPoints: 320),
        Gift(id: "hat_sunhat", type: .hat, requiredPoints: 336),
        Gift(id: "hat_fancy", type: .hat, requiredPoints: 352),
        Gift(id: "hat_beretred", type: .hat, requiredPoints: 368),
        Gift(id: "acc_glasses", type: .accessory, requiredPoints: 384),
        Gift(id: "bg_forest", type: .background, requiredPoints: 400),
        Gift(id: "hat_oriole", type: .hat, requiredPoints: 416),
        Gift(id: "hat_dog", type: .hat, requiredPoints: 432, customMessage: "Woof!"),
        Gift(id: "hat_cat", type: .hat, requiredPoints: 448, customMessage: "Meow!"),
        Gift(id: "bg_farm", type: .background, requiredPoints: 464),
        Gift(id: "hat_strawhat", type: .hat, requiredPoints: 480),
        Gift(id: "hat_horse", type: .hat, requiredPoints: 496, customMessage: "Neigh!"),
        Gift(id: "hat_rodent", type: .hat, requiredPoints: 512),
        Gift(id: "hat_rabbit", type: .hat, requiredPoints: 528),
        // Baltimore Harbor BG - 544
        Gift(id: "hat_beaniefootball", type: .hat, requiredPoints: 560),
        Gift(id: "hat_capbaseball", type: .hat, requiredPoints: 576, customMessage: "Play ball!"),
        // Annapolis BG - 592
        Gift(id: "hat_tophat", type: .hat, requiredPoints: 608),
        Gift(id: "acc_monocle", type: .accessory, requiredPoints: 624),
        Gift(id: "hat_bow", type: .hat, requiredPoints: 640),
        // Elicott City BG - 656
        Gift(id: "hat_capgreen", type: .hat, requiredPoints: 672),
        // Striped Bow Hat - 688
        // Historic MD BG - 704
        Gift(id: "hat_colonial", type: .hat, requiredPoints: 720, customMessage: "How do you do?"),
        Gift(id: "hat_cowboy", type: .hat, requiredPoints: 736, customMessage: "Howdy!"),
        Gift(id: "bg_falltrees", type: .background, requiredPoints: 752),
        Gift(id: "hat_beretblack", type: .hat, requiredPoints: 768),
        Gift(id: "hat_paper", type: .hat, requiredPoints: 784),
        // Space BG - 800
        // Eco Crown Hat - 816
    ]
    
    func giftUnlockedWhen(pointsBefore: Double, pointsAfter: Double) -> Gift? {
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
