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
        return .primaryBlue
    }
    
    // Specifically for float label text fields
    static var primaryColorDark: UIColor {
        return .primaryPurple
    }
    
    static var primaryColorAccountPicker: UIColor {
        return .primaryBlue
    }
    
    static var switchBackgroundColor: UIColor {
        switch Configuration.shared.opco {
        case .bge:
            return UIColor(red: 24/255, green: 51/255, blue: 18/255, alpha: 1)
        case .comEd:
            return UIColor(red: 61/255, green: 3/255, blue: 17/255, alpha: 1)
        case .ace, .delmarva, .peco, .pepco:
            return UIColor(red: 0/255, green: 35/255, blue: 55/255, alpha: 1)
        }
    }
    
    static var stormPrimaryColor: UIColor {
        switch Configuration.shared.opco {
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
