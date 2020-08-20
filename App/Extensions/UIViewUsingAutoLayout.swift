//
//  UIViewUsingAutoLayout.swift
//  Mobile
//
//  Created by Sam Francis on 11/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

fileprivate let maxTabletWidth: CGFloat = 460

extension UIView {
    func usingAutoLayout() -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }
    
    func addTabletWidthConstraints(horizontalPadding: CGFloat, padMaxWidth: Bool = false) {
        guard let superview = superview else { return }
        
        let leading = leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: horizontalPadding)
        leading.priority = UILayoutPriority(rawValue: 999)
        leading.isActive = true
        leadingAnchor.constraint(greaterThanOrEqualTo: superview.leadingAnchor, constant: horizontalPadding).isActive = true
        
        let trailing = trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -horizontalPadding)
        trailing.priority = UILayoutPriority(rawValue: 999)
        trailing.isActive = true
        trailingAnchor.constraint(lessThanOrEqualTo: superview.trailingAnchor, constant: -horizontalPadding).isActive = true
        
        centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
        
        let maxWidth = maxTabletWidth - (padMaxWidth ? horizontalPadding : 0)
        let width = widthAnchor.constraint(equalToConstant: maxWidth)
        width.priority = UILayoutPriority(rawValue: 999)
        width.isActive = true
        widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth).isActive = true
    }
}
