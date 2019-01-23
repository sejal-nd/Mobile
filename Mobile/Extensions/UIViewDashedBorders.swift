//
//  UIViewDashedBorders.swift
//  Mobile
//
//  Created by Marc Shilling on 10/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIView {
    func addDashedBorder(color: UIColor) {
        let borderColor = color.cgColor
        
        let shapeLayer:CAShapeLayer = CAShapeLayer()
        let frameSize = self.frame.size
        let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: frameSize.width / 2, y: frameSize.height / 2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = borderColor
        shapeLayer.lineWidth = 1
        shapeLayer.lineJoin = .round
        shapeLayer.lineDashPattern = [4, 1]
        shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 10).cgPath
        
        self.layer.addSublayer(shapeLayer)
    }
}
