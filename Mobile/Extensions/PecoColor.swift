//
//  PecoColor.swift
//  Mobile
//
//  Created by Marc Shilling on 2/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIColor {
    @nonobjc static var primaryColor: UIColor {
        return UIColor(red: 0/255, green: 119/255, blue: 187/255, alpha: 1)
    }
    
    // ADA compliance color
    @nonobjc static var primaryColorADA: UIColor {
        return UIColor(red: 0/255, green: 98/255, blue: 154/255, alpha: 1)
    }
    
    // Specifically for float label text fields
    @nonobjc static var primaryColorDark: UIColor {
        return UIColor(red: 0/255, green: 79/255, blue: 125/255, alpha: 1)
    }
    
}
