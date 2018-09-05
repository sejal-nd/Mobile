//
//  ComEdColor.swift
//  Mobile
//
//  Created by Marc Shilling on 2/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIColor {
    
    @nonobjc static var primaryColor: UIColor {
        return UIColor(red: 206/255, green: 17/255, blue: 65/255, alpha: 1)
    }
    
    // ADA compliance color
    @nonobjc static var primaryColorADA: UIColor {
        return UIColor(red: 166/255, green: 13/255, blue: 52/255, alpha: 1)
    }
    
    // Specifically for float label text fields
    @nonobjc static var primaryColorDark: UIColor {
        return UIColor(red: 120/255, green: 12/255, blue: 39/255, alpha: 1)
    }
    
    @nonobjc static var primaryColorAccountPicker: UIColor {
        return UIColor(red: 187/255, green: 21/255, blue: 65/255, alpha: 1)
    }
    
    @nonobjc static var switchBackgroundColor: UIColor {
        return UIColor(red: 61/255, green: 3/255, blue: 17/255, alpha: 1)
    }
    
}
