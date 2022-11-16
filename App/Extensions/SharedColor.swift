//
//  SharedColor.swift
//  Mobile
//
//  Created by Marc Shilling on 2/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIColor {

    // MARK: Brand Colors

    /// Exelon Dark Blue #170D67
    static var primaryBlue: UIColor {
        return UIColor(named: "primaryBlue")!
    }

    /// Exelon Purple #6E06C1
    static var primaryPurple: UIColor {
        return UIColor(named: "primaryPurple")!
    }

    /// Exelon Light Blue #3A5CFF
    static var secondaryBlue: UIColor {
        return UIColor(named: "secondaryBlue")!
    }

    /// Exelon Green #00E4A5
    static var secondaryGreen: UIColor {
        return UIColor(named: "secondaryGreen")!
    }

    /// Exelon Gray #E8E7F0
    static var secondaryGray: UIColor {
        return UIColor(named: "secondaryGray")!
    }

    /// Exelon Orange #FF8300
    static var tertiaryOrange: UIColor {
        return UIColor(named: "tertiaryOrange")!
    }

    /// Exelon Yellow #FFD700
    static var tertiaryYellow: UIColor {
        return UIColor(named: "tertiaryYellow")!
    }

    // MARK: UI Colors

    /// Action Dark #170D67 (Same as Primary Dark Blue)
    static var actionBrand: UIColor {
        return primaryBlue
    }

    /// Action Dark #103870
    static var actionDark: UIColor {
        return UIColor(named: "actionDark")!
    }

    /// Action Primary #0059A4
    static var actionPrimary: UIColor {
        return UIColor(named: "actionPrimary")!
    }

    /// Neutral #020E1E, 95%
    static var labelColor: UIColor {
        return neutralDarker
    }

    /// Neutral #0F1A2A
    static var neutralDarker: UIColor {
        return UIColor(named: "neutralDarker")!
    }

    /// Neutral #5A626D
    static var neutralDark: UIColor {
        return UIColor(named: "neutralDark")!
    }

    /// Neutral #8D929A
    static var neutralMedium: UIColor {
        return UIColor(named: "neutralMedium")!
    }

    /// Neutral #C0C3C7
    static var neutralLight: UIColor {
        return UIColor(named: "neutralLight")!
    }

    /// Neutral #E5E6E8
    static var neutralLighter: UIColor {
        return UIColor(named: "neutralLighter")!
    }

    /// Neutral #F7F7F8
    static var neutralLightest: UIColor {
        return UIColor(named: "neutralLightest")!
    }

    // MARK: Status Colors

    /// Success Primary #20804F
    static var successPrimary: UIColor {
        return UIColor(named: "successPrimary")!
    }

    /// Success Primary #D5EFE2
    static var successMedium: UIColor {
        return UIColor(named: "successMedium")!
    }

    /// Success Primary #F8FCFA
    static var successLight: UIColor {
        return UIColor(named: "successLight")!
    }

    /// Attention Primary #FE7212
    static var attentionPrimary: UIColor {
        return UIColor(named: "attentionPrimary")!
    }

    /// Attention Medium #FFE3D0
    static var attentionMedium: UIColor {
        return UIColor(named: "attentionMedium")!
    }

    /// Attention Light #FFFAF8
    static var attentionLight: UIColor {
        return UIColor(named: "attentionLight")!
    }

    // Error Primary #BF002F
    static var errorPrimary: UIColor {
        return UIColor(named: "errorPrimary")!
    }

    // Error Medium #F2CCD5
    static var errorMedium: UIColor {
        return errorPrimary.withAlphaComponent(20)
    }

    // Error Light #FDF7F8
    static var errorLight: UIColor {
        return errorPrimary.withAlphaComponent(3)
    }





    @nonobjc static var blackText: UIColor {
        return UIColor(red: 35/255, green: 31/255, blue: 32/255, alpha: 1)
    }
    
    @nonobjc static var deepGray: UIColor {
        return UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 1)
    }
    
    @nonobjc static var middleGray: UIColor {
        return UIColor(red: 115/255, green: 115/255, blue: 115/255, alpha: 1)
    }
    
    @nonobjc static var accentGray: UIColor {
        return UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 1)
    }
    
    @nonobjc static var softGray: UIColor {
        return UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)
    }
    
    @nonobjc static var ctaBlue: UIColor {
        return UIColor(red: 16/255, green: 56/255, blue: 112/255, alpha: 1)
    }
    
    @nonobjc static var actionBlue: UIColor {
        return UIColor(red: 0/255, green: 89/255, blue: 164/255, alpha: 1)
    }
    
    @nonobjc static var attentionOrange: UIColor {
        return UIColor(red: 254/255, green: 114/255, blue: 18/255, alpha: 1)
    }
    
    @nonobjc static var lightbulbYellow: UIColor {
        return UIColor(red: 255/255, green: 173/255, blue: 40/255, alpha: 1)
    }
    
    @nonobjc static var successGreen: UIColor {
        return UIColor(red: 120/255, green: 190/255, blue: 32/255, alpha: 1)
    }
    
    @nonobjc static var successGreenText: UIColor {
        return UIColor(red: 0/255, green: 122/255, blue: 51/255, alpha: 1)
    }
    
    @nonobjc static var mediumSpringBud: UIColor {
        return UIColor(red: 188/255, green: 228/255, blue: 139/255, alpha: 1)
    }
    
    @nonobjc static var mediumJungleGreen: UIColor {
        return UIColor(red: 44/255, green: 38/255, blue: 51/255, alpha: 1)
    }
    
    @nonobjc static var richElectricBlue: UIColor {
        return UIColor(red: 13/255, green: 157/255, blue: 219/255, alpha: 1)
    }
    
    @nonobjc static var burntSienna: UIColor {
        return UIColor(red: 238/255, green: 127/255, blue: 75/255, alpha: 1)
    }
    
    @nonobjc static var autoFillYellow: UIColor {
        return UIColor(red: 234/255, green: 230/255, blue: 188/255, alpha: 1)
    }
    
    @nonobjc static var bgeGreen: UIColor {
        // Old BGE primary color
        return UIColor(red: 102/255, green: 179/255, blue: 96/255, alpha: 1)
    }
    
    @nonobjc static var stormModeBlack: UIColor {
        return UIColor(red: 44/255, green: 38/255, blue: 51/255, alpha: 1)
    }
    
    @nonobjc static var stormModeGray: UIColor {
        return UIColor(red: 65/255, green: 60/255, blue: 71/255, alpha: 1)
    }
    
    @nonobjc static var stormModeLightGray: UIColor {
        return UIColor(red: 84/255, green: 79/255, blue: 89/255, alpha: 1)
    }
    
    @nonobjc static var roseQuartz: UIColor {
        return UIColor(red: 164/255, green: 155/255, blue: 174/255, alpha: 1)
    }
    
}
