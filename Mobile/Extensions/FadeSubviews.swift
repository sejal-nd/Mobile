//
//  FadeSubviews.swift
//  Mobile
//
//  Created by Sam Francis on 5/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIView {
    func fadeSubviews(fadeAmount amount: CGFloat, animationDuration: TimeInterval = 0.0, delay: TimeInterval = 0.0, excludedViews: [UIView] = [UIView](), completion: ((Bool) -> Void)? = nil) {
        let subviews = self.subviews + self.subviews.flatMap { $0.subviews }
        UIView.animate(withDuration: animationDuration, delay: delay,  animations: {
            subviews.filter { !excludedViews.contains($0) }.forEach { subview in
                if !(subview is UIStackView) {
                    subview.alpha = amount
                } else {
                    subview.fadeSubviews(fadeAmount: amount, animationDuration: animationDuration)
                }
            }
        }, completion: completion)
    }
    
    func fadeView(fadeAmount amount: CGFloat, animationDuration: TimeInterval = 0.0, delay: TimeInterval = 0.0, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: animationDuration, delay: delay,  animations: {
            self.alpha = amount
        }, completion: completion)
    }
}
