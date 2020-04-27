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
        // Updated 6/1/2017: BGE primaryColor now IS the ADA compliance color. Keeping \
        // primaryColorADA below for compatibility with other OpCos
        return UIColor(red: 0/255, green: 103/255, blue: 177/255, alpha: 1)
    }
    
    // ADA compliance color
    @nonobjc static var primaryColorADA: UIColor {
        return UIColor(red: 0/255, green: 103/255, blue: 177/255, alpha: 1)
    }
    
    // Specifically for float label text fields
    @nonobjc static var primaryColorDark: UIColor {
        return .yellow//UIColor(red: 26/255, green: 91/255, blue: 14/255, alpha: 1)
    }
    
    @nonobjc static var primaryColorAccountPicker: UIColor {
        return .yellow //UIColor(red: 54/255, green: 121/255, blue: 42/255, alpha: 1)
    }
    
    @nonobjc static var switchBackgroundColor: UIColor {
        return .yellow //UIColor(red: 24/255, green: 51/255, blue: 18/255, alpha: 1)
    }
    
    @nonobjc static var stormPrimaryColor: UIColor {
        return .yellow//.bgeGreen
    }
    
}
