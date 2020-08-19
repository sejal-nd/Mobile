//
//  Color+OpCo.swift
//  BGE
//
//  Created by Joseph Erlandson on 5/7/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIColor {
    static var primaryColor: UIColor {
        switch Environment.shared.opco {
        case .bge:
            return UIColor(red: 61/255, green: 132/255, blue: 48/255, alpha: 1)
        case .comEd:
            return UIColor(red: 206/255, green: 17/255, blue: 65/255, alpha: 1)
        case .peco:
            return UIColor(red: 0/255, green: 119/255, blue: 187/255, alpha: 1)
        case .pepco:
            return UIColor(red: 0/255, green: 103/255, blue: 177/255, alpha: 1)
        case .delmarva:
            return UIColor(red: 0/255, green: 103/255, blue: 177/255, alpha: 1)
        case .ace:
            return UIColor(red: 0/255, green: 103/255, blue: 177/255, alpha: 1)
        }
    }
    
    // Specifically for float label text fields
    static var primaryColorDark: UIColor {
        switch Environment.shared.opco {
        case .bge:
            return UIColor(red: 26/255, green: 91/255, blue: 14/255, alpha: 1)
        case .comEd:
            return UIColor(red: 120/255, green: 12/255, blue: 39/255, alpha: 1)
        case .peco:
            return UIColor(red: 0/255, green: 98/255, blue: 154/255, alpha: 1)
        case .ace, .delmarva, .pepco:
            return UIColor(red: 0/255, green: 89/255, blue: 154/255, alpha: 1)
        }
    }
    
    static var primaryColorAccountPicker: UIColor {
        switch Environment.shared.opco {
        case .bge:
            return UIColor(red: 54/255, green: 121/255, blue: 42/255, alpha: 1)
        case .comEd:
            return UIColor(red: 187/255, green: 21/255, blue: 65/255, alpha: 1)
        case .peco:
            return UIColor(red: 0/255, green: 111/255, blue: 174/255, alpha: 1)
        case .pepco, .ace, .delmarva:
            return .primaryColor
        }
    }
    
    static var switchBackgroundColor: UIColor {
        switch Environment.shared.opco {
        case .bge:
            return UIColor(red: 24/255, green: 51/255, blue: 18/255, alpha: 1)
        case .comEd:
            return UIColor(red: 61/255, green: 3/255, blue: 17/255, alpha: 1)
        case .peco:
            return UIColor(red: 0/255, green: 35/255, blue: 55/255, alpha: 1)
        case .pepco, .ace, .delmarva:
            return .primaryColor
        }
    }
    
    static var stormPrimaryColor: UIColor {
        switch Environment.shared.opco {
        case .bge:
            return .bgeGreen
        case .comEd:
            return .primaryColor
        case .peco:
            return UIColor(red: 0/255, green: 162/255, blue: 255/255, alpha: 1)
        case .pepco, .ace, .delmarva:
            return .roseQuartz
        }
    }
    
}
