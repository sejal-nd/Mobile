//
//  UIColor+Image.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/8/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIColor {
    func image() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 10))
        let ctx = UIGraphicsGetCurrentContext()!
        self.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}
