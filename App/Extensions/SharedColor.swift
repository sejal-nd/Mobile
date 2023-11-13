//
//  SharedColor.swift
//  Mobile
//
//  Created by Marc Shilling on 2/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIColor {
    static var actionBrand: UIColor {
        return .actionPrimary
    }
    
    @nonobjc static var blackText: UIColor {
        return .neutralDarker
    }
    
    @nonobjc static var deepGray: UIColor {
        return .neutralDark
    }
    
    @nonobjc static var middleGray: UIColor {
        return .neutralMedium
    }
    
    @nonobjc static var accentGray: UIColor {
        return .neutralLight
    }
    
    @nonobjc static var softGray: UIColor {
        return .neutralLightest
    }
    
    @nonobjc static var attentionOrange: UIColor {
        return .attentionPrimary
    }
    
    @nonobjc static var successGreen: UIColor {
        return .successPrimary
    }
    
    @nonobjc static var successGreenText: UIColor {
        return .successPrimary
    }

    // MARK: Storm Mode Colors

    @nonobjc static var stormModeBackground: UIColor {
        return .primaryColor
    }

    // #3854E1
    @nonobjc static var stormModeGradient: UIColor {
        return UIColor(red: 56/255, green: 84/255, blue: 225/255, alpha: 1)
    }
    
    @nonobjc static var stormModeGray: UIColor {
        return UIColor(red: 65/255, green: 60/255, blue: 71/255, alpha: 1)
    }
    
    @nonobjc static var stormModeLightGray: UIColor {
        return UIColor(red: 84/255, green: 79/255, blue: 89/255, alpha: 1)
    }

    // MARK: Misc Colors

    // #0D9DDB
    @nonobjc static var thermostatCool: UIColor {
        return UIColor(red: 13/255, green: 157/255, blue: 219/255, alpha: 1)
    }

    // #EE7F4B
    @nonobjc static var thermostatHeat: UIColor {
        return UIColor(red: 238/255, green: 127/255, blue: 75/255, alpha: 1)
    }

    // TODO what is this color
    @nonobjc static var autoFillYellow: UIColor {
        return UIColor(red: 234/255, green: 230/255, blue: 188/255, alpha: 1)
    }

    @nonobjc static var roseQuartz: UIColor {
        return UIColor(red: 164/255, green: 155/255, blue: 174/255, alpha: 1)
    }
}
