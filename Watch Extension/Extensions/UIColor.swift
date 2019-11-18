//
//  UIColor.swift
//  Mobile
//
//  Created by Joseph Erlandson on 10/8/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import WatchKit

extension UIColor {
    static var primary: UIColor {
        switch Environment.shared.opco {
        case .bge:
            return UIColor(red: 103.0/255.0, green: 179.0/255.0, blue: 96.0/255.0, alpha: 1.0)
        case .comEd:
            return UIColor(red: 235/255.0, green: 0/255.0, blue: 61/255.0, alpha: 1.0)
        case .peco:
            return UIColor(red: 0.0/255.0, green: 162.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        }
    }
    
    static var errorRed: UIColor {
        return UIColor(red: 255.0 / 255.0, green: 51.0 / 255.0, blue: 0.0 / 255.0, alpha: 1.0)
    }
}
