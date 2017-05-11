//
//  BGEColor.swift
//  Mobile
//
//  Created by Marc Shilling on 2/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIColor {
    @nonobjc static var primaryColor: UIColor {
        get {
            return UIColor(red: 102/255, green: 179/255, blue: 96/255, alpha: 1)
        }
    }
    
    // ADA compliance color
    @nonobjc static var primaryColorADA: UIColor {
        get {
            return UIColor(red: 61/255, green: 132/255, blue: 48/255, alpha: 1)
        }
    }
    
    // Specifically for float label text fields
    @nonobjc static var primaryColorDark: UIColor {
        get {
            return UIColor(red: 26/255, green: 91/255, blue: 14/255, alpha: 1)
        }
    }

}
