//
//  SharedColor.swift
//  Mobile
//
//  Created by Marc Shilling on 2/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIColor {
    class var primaryButtonBackground: UIColor {
        get {
            return UIColor(red: 16/255, green: 56/255, blue: 112/255, alpha: 1)
        }
    }

    class var primaryButtonHighlight: UIColor {
        get {
           return UIColor(red: 0/255, green: 38/255, blue: 88/255, alpha: 1)
        }
    }
    
    class var secondaryButtonHighlight: UIColor {
        get {
            return UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1)
        }
    }

    class var tableViewBackgroundColor: UIColor {
        get {
            return UIColor(red: 215/255, green: 215/255, blue: 215/255, alpha: 0.15)
        }
    }
    
    class var mediumPersianBlue: UIColor {
        get {
            return UIColor(red: 0/255, green: 89/255, blue: 164/255, alpha: 1)
        }
    }
    
    class var dimGray: UIColor {
        get {
            return UIColor(red: 97/255, green: 97/255, blue: 97/255, alpha: 1)
        }
    }
    
    class var silver: UIColor {
        get {
            return UIColor(red: 187/255, green: 187/255, blue: 187/255, alpha: 1)
        }
    }
    
    class var oldLavender: UIColor {
        get {
            return UIColor(red: 115/255, green: 115/255, blue: 115/255, alpha: 1)
        }
    }

    class var timberwolf: UIColor {
        get {
            return UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 1)
        }
    }

    class var darkJungleGreen: UIColor {
        get {
            return UIColor(red: 35/255, green: 31/255, blue: 32/255, alpha: 1)
        }
    }
    
    class var outerSpace: UIColor {
        get {
            return UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 1)
        }
    }

//    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
//        return self.adjust(by: abs(percentage))
//    }
//
//    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
//        return self.adjust(by: -1 * abs(percentage))
//    }
//
//    func adjust(by percentage:CGFloat=30.0) -> UIColor? {
//        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0;
//        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
//            return UIColor(red: min(r + percentage/100, 1.0),
//                           green: min(g + percentage/100, 1.0),
//                           blue: min(b + percentage/100, 1.0),
//                           alpha: a)
//        } else {
//            return nil
//        }
//    }
}
