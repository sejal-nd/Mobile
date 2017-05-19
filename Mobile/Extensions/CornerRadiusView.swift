//
//  CornerRadiusView.swift
//  Mobile
//
//  Created by Marc Shilling on 5/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIView {
    private func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let bounds = self.bounds
        
        let maskPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = maskPath.cgPath
        
        self.layer.mask = maskLayer
        
        let frameLayer = CAShapeLayer()
        frameLayer.frame = bounds
        frameLayer.path = maskPath.cgPath
        frameLayer.strokeColor = nil
        frameLayer.fillColor = nil
        
        self.layer.addSublayer(frameLayer)
    }
    
    func roundTopCorners(radius: CGFloat) {
        self.roundCorners(corners: [UIRectCorner.topLeft, UIRectCorner.topRight], radius:radius)
    }
    
    func roundBottomCorners(radius: CGFloat) {
        self.roundCorners(corners: [UIRectCorner.bottomLeft, UIRectCorner.bottomRight], radius:radius)
    }
    
}
