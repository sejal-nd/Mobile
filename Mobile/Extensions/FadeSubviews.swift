//
//  FadeSubviews.swift
//  Mobile
//
//  Created by Sam Francis on 5/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIView {
    func fadeSubviews(fadeAmount amount: CGFloat, animationDuration: TimeInterval, excludedViews: [UIView] = [UIView]()) {
        let subviews = self.subviews + self.subviews.flatMap { $0.subviews }
        UIView.animate(withDuration: animationDuration, animations: {
            subviews.filter { !excludedViews.contains($0) }.forEach { subview in
                if !(subview is UIStackView) {
                    subview.alpha = amount
                } else {
                    subview.fadeSubviews(fadeAmount: amount, animationDuration: animationDuration)
                }
            }
        })
    }
}
