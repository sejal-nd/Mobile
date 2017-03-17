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
            return UIColor(red: 204/255, green: 0/255, blue: 51/255, alpha: 1)
        }
    }
    
    @nonobjc static var primaryColorLight: UIColor {
        get {
            return UIColor(red: 204/255, green: 0/255, blue: 51/255, alpha: 0.63)
        }
    }
    
    @nonobjc static var primaryColorDark: UIColor {
        get {
            return UIColor(red: 133/255, green: 0/255, blue: 33/255, alpha: 1)
        }
    }
}
