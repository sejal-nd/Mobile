//
//  SharedColor.swift
//  Mobile
//
//  Created by Marc Shilling on 2/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIColor {
    
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
    
    @nonobjc static var errorRed: UIColor {
        return UIColor(red: 113/255, green: 0/255, blue: 28/255, alpha: 1)
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
    
//    convenience init(hex: String, alpha: CGFloat = 1) {
//        assert(hex[hex.startIndex] == "#", "Expected hex string of format #RRGGBB")
//        
//        let scanner = Scanner(string: hex)
//        scanner.scanLocation = 1 // skip #
//        
//        var rgb: UInt32 = 0
//        scanner.scanHexInt32(&rgb)
//        
//        self.init(
//            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
//            green: CGFloat((rgb & 0xFF00) >>  8) / 255.0,
//            blue: CGFloat((rgb & 0xFF)) / 255.0,
//            alpha: alpha
//        )
//    }
//    
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
