//
//  SharedColor.swift
//  Mobile
//
//  Created by Marc Shilling on 2/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIColor {

    // The color to be used for the pressed/highlighted state for white buttons/cells
    @nonobjc static var whiteButtonHighlight: UIColor {
        get {
            return UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1)
        }
    }
    
    // CTA Blue
    @nonobjc static var darkMidnightBlue: UIColor {
        get {
            return UIColor(red: 16/255, green: 56/255, blue: 112/255, alpha: 1)
        }
    }
    
    // Action Blue
    @nonobjc static var mediumPersianBlue: UIColor {
        get {
            return UIColor(red: 0/255, green: 89/255, blue: 164/255, alpha: 1)
        }
    }
        
    // "Black" Text
    @nonobjc static var darkJungleGreen: UIColor {
        get {
            return UIColor(red: 35/255, green: 31/255, blue: 32/255, alpha: 1)
        }
    }
    
    // Deep Gray
    @nonobjc static var outerSpace: UIColor {
        get {
            return UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 1)
        }
    }
    
    // Middle Gray
    @nonobjc static var oldLavender: UIColor {
        get {
            return UIColor(red: 115/255, green: 115/255, blue: 115/255, alpha: 1)
        }
    }
    
    // Accent Gray
    @nonobjc static var timberwolf: UIColor {
        get {
            return UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 1)
        }
    }
    
    // Soft Gray
    @nonobjc static var whiteSmoke: UIColor {
        get {
            return UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)
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
