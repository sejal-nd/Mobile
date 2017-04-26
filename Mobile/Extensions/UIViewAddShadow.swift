//
//  UIViewAddShadow.swift
//  Mobile
//
//  Created by Marc Shilling on 4/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

extension UIView {
    func addShadow(color: UIColor, opacity: Float, offset: CGSize, radius: Float) {
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = CGFloat(radius)
        self.layer.masksToBounds = false
    }
}
