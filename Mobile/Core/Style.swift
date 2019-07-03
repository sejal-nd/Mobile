//
//  Style.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/3/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

struct Style {
    static func applyLargeNav() {
        
        UINavigationBar.appearance().setBackgroundImage(nil, for: .default)
        UINavigationBar.appearance().shadowImage = UIColor.primaryColor.as1ptImage()
        if #available(iOS 11.0, *) {
            UINavigationBar.appearance().largeTitleTextAttributes = [
                .font: OpenSans.bold.of(size: 20)
            ]
        } else {
            // Fallback on earlier versions
        }
        UINavigationBar.appearance().titleTextAttributes = [
            .font: OpenSans.bold.of(size: 18)
        ]
        if #available(iOS 11.0, *) {
//            UINavigationBar.appearance().largeTitleDisplayMode
            UINavigationBar.appearance().prefersLargeTitles = true
        } else {
            // Fallback on earlier versions
        }
        
        
//
//
//        let navigationBar = navigationController!.navigationBar
//        navigationBar.setBackgroundImage(nil,
//                                         for: .default)
//
//        navigationBar.shadowImage = //UIImage()
//
//        let font = UIFont(name: "Roboto-Regular", size: 60)
//        let fontMetrics = UIFontMetrics(forTextStyle: .body)
//
//        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.font: fontMetrics.scaledFont(for: font!)]
//        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "Roboto-Regular", size: 20)!]
    }
}

extension UIColor {
    func as1ptImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 10))
        let ctx = UIGraphicsGetCurrentContext()!
        self.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}
