//
//  SharedColor.swift
//  Mobile
//
//  Created by Marc Shilling on 2/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIColor {
    class var buttonBackgroundNormalColor: UIColor {
        get {
            return UIColor(red: 16/255, green: 56/255, blue: 112/255, alpha: 1)
        }
    }
    
    class var buttonBackgroundHighlightColor: UIColor {
        get {
           return UIColor(red: 0/255, green: 38/255, blue: 88/255, alpha: 1)
        }
    }
    
    class var buttonBackgroundDisabledColor: UIColor {
        get {
            return UIColor(red: 115/255, green: 115/255, blue: 115/255, alpha: 1)
        }
    }
    
    class var textButtonColor: UIColor {
        get {
            return UIColor(red: 0/255, green: 90/255, blue: 163/255, alpha: 1)
        }
    }
    
    class var switchOffColor: UIColor {
        get {
            return UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 1)
        }
    }
    
    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage))
    }
    
    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage))
    }
    
    func adjust(by percentage:CGFloat=30.0) -> UIColor? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0;
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return UIColor(red: min(r + percentage/100, 1.0),
                           green: min(g + percentage/100, 1.0),
                           blue: min(b + percentage/100, 1.0),
                           alpha: a)
        } else{
            return nil
        }
    }
}
