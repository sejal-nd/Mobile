//
//  BGEColor.swift
//  Mobile
//
//  Created by Marc Shilling on 2/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIColor {
    class var primaryColor: UIColor {
        get {
            return UIColor(red: 110/255, green: 184/255, blue: 96/255, alpha: 1)
        }
    }
    
    class var primaryColorLight: UIColor {
        get {
            return UIColor(red: 129/255, green: 201/255, blue: 115/255, alpha: 0.7)
        }
    }
    
    class var primaryColorDark: UIColor {
        get {
            return UIColor(red: 26/255, green: 91/255, blue: 14/255, alpha: 1)
        }
    }
}
