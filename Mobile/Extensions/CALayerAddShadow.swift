//
//  CALayerAddShadow.swift
//  Mobile
//
//  Created by Joseph Erlandson on 6/6/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

extension CALayer {
    
    func addShadow(color: UIColor, opacity: Float, offset: CGSize, radius: Float) {
        shadowColor = color.cgColor
        shadowOpacity = opacity
        shadowOffset = offset
        shadowRadius = CGFloat(radius)
        masksToBounds = false
    }
    
}
