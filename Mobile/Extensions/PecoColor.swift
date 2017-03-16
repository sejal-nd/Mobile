//
//  PecoColor.swift
//  Mobile
//
//  Created by Marc Shilling on 2/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIColor {
    class var primaryColor: UIColor {
        get {
            return UIColor(red: 2/255, green: 142/255, blue: 206/255, alpha: 1)
        }
    }
    
    class var primaryColorLight: UIColor {
        get {
            return UIColor(red: 2/255, green: 142/255, blue: 206/255, alpha: 0.7)
        }
    }
    
    class var primaryColorDark: UIColor {
        get {
            return UIColor(red: 0/255, green: 83/255, blue: 122/255, alpha: 1)
        }
    }
}
