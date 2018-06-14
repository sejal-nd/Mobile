//
//  UIViewRoundCorners.swift
//  BGE
//
//  Created by Joseph Erlandson on 6/5/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIView {
    
    /**
     Rounds the given set of corners to the specified radius
     
     - parameter corners: Corners to round
     - parameter radius:  Radius to round to
     */
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        if #available(iOS 11.0, *) {
            layer.maskedCorners = corners.cornerMask
            layer.cornerRadius = radius
        } else {
            _roundWithMask(corners: corners, radius: radius)
        }
    }
    
    /**
     Rounds the given set of corners to the specified radius with a border
     
     - parameter corners:     Corners to round
     - parameter radius:      Radius to round to
     - parameter borderColor: The border color
     - parameter borderWidth: The border width
     */
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat, borderColor: UIColor, borderWidth: CGFloat) {
        if #available(iOS 11.0, *) {
            layer.maskedCorners = corners.cornerMask
            layer.cornerRadius = radius
            layer.borderColor = borderColor.cgColor
            layer.borderWidth = borderWidth
        } else {
            let mask = _roundWithMask(corners: corners, radius: radius)
            addBorder(mask: mask, borderColor: borderColor, borderWidth: borderWidth)
        }
    }
    
    /**
     Fully rounds an autolayout view (e.g. one with no known frame) with the given diameter and border
     
     - parameter diameter:    The view's diameter
     - parameter borderColor: The border color
     - parameter borderWidth: The border width
     */
    func fullyRoundCorners(diameter: CGFloat, borderColor: UIColor, borderWidth: CGFloat) {
        layer.masksToBounds = true
        layer.cornerRadius = diameter / 2
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
    }
    
}

private extension UIView {
    
    @available(iOS, deprecated: 11.0, message: "In iOS 11+, use `CALayer.maskedCorners` instead")
    @discardableResult func _roundWithMask(corners: UIRectCorner, radius: CGFloat) -> CAShapeLayer {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
        return mask
    }
    
    @available(iOS, deprecated: 11.0, message: "In iOS 11+, use `CALayer.maskedCorners` instead")
    func addBorder(mask: CAShapeLayer, borderColor: UIColor, borderWidth: CGFloat) {
        let borderLayer = CAShapeLayer()
        borderLayer.path = mask.path
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.lineWidth = borderWidth
        borderLayer.frame = bounds
        layer.addSublayer(borderLayer)
    }
    
}

extension UIRectCorner {
    var cornerMask: CACornerMask {
        var cornerMask: CACornerMask = []
        
        if contains(.topLeft) {
            cornerMask.formUnion(.layerMinXMinYCorner)
        }
        
        if contains(.topRight) {
            cornerMask.formUnion(.layerMaxXMinYCorner)
        }
        
        if contains(.bottomLeft) {
            cornerMask.formUnion(.layerMinXMaxYCorner)
        }
        
        if contains(.bottomRight) {
            cornerMask.formUnion(.layerMaxXMaxYCorner)
        }
        
        return cornerMask
    }
}
