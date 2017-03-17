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
        get {
            return UIColor(red: 206/255, green: 17/255, blue: 65/255, alpha: 1)
        }
    }
    
    // ADA compliance color
    @nonobjc static var primaryColorDark: UIColor {
        get {
            return UIColor(red: 166/255, green: 13/255, blue: 52/255, alpha: 1)
        }
    }
    
    @nonobjc static var floatLabelColor: UIColor {
        get {
            return UIColor(red: 120/255, green: 12/255, blue: 39/255, alpha: 1)
        }
    }
    
    // Used on Outage screen reported state circles
    @nonobjc static var primaryColorLight: UIColor {
        get {
            return UIColor(red: 204/255, green: 0/255, blue: 51/255, alpha: 0.63)
        }
    }
}
