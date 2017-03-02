//
//  IndividualBorders.swift
//  Mobile
//
//  Created by Marc Shilling on 3/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIView {
    @discardableResult func addRightBorder(color: UIColor, width: CGFloat) -> CALayer {
        let layer = CALayer()
        layer.borderColor = color.cgColor
        layer.borderWidth = width
        layer.frame = CGRect(x: self.frame.size.width - width, y: 0, width: width, height: self.frame.size.height)
        self.layer.addSublayer(layer)
        return layer
    }
    
    @discardableResult func addLeftBorder(color: UIColor, width: CGFloat) -> CALayer {
        let layer = CALayer()
        layer.borderColor = color.cgColor
        layer.borderWidth = width
        layer.frame = CGRect(x: 0, y: 0, width: width, height: self.frame.size.height)
        self.layer.addSublayer(layer)
        return layer
    }
    
    @discardableResult func addTopBorder(color: UIColor, width: CGFloat) -> CALayer {
        let layer = CALayer()
        layer.borderColor = color.cgColor
        layer.borderWidth = width
        layer.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: width)
        self.layer.addSublayer(layer)
        return layer
    }
    
    @discardableResult func addBottomBorder(color: UIColor, width: CGFloat) -> CALayer {
        let layer = CALayer()
        layer.borderColor = color.cgColor
        layer.borderWidth = width
        layer.frame = CGRect(x: 0, y: self.frame.size.height - width, width: self.frame.size.width, height: width)
        self.layer.addSublayer(layer)
        return layer
    }
}
