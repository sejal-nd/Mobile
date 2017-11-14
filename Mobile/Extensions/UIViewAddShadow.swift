//
//  UIViewAddShadow.swift
//  Mobile
//
//  Created by Marc Shilling on 4/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

extension UIView {
    func addShadow(color: UIColor, opacity: Float, offset: CGSize, radius: Float) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = CGFloat(radius)
        layer.masksToBounds = false
    }
}
