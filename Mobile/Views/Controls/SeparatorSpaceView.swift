//
//  SeparatorSpaceView.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class SeparatorSpaceView: UIView {
    
    var heightConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = heightAnchor.constraint(equalToConstant: 10.0)
        heightConstraint.priority = UILayoutPriority(rawValue: 999)
        heightConstraint.isActive = true
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 312, height: 10)
    }
    
    static func create(withHeight height: CGFloat? = nil) -> SeparatorSpaceView {
        let view = SeparatorSpaceView(frame: .zero)
        
        if let height = height {
            view.removeConstraint(view.heightConstraint)
            
            view.heightConstraint = view.heightAnchor.constraint(equalToConstant: height)
            view.heightConstraint.priority = UILayoutPriority(rawValue: 999)
            view.heightConstraint.isActive = true
        }
        
        return view
    }
}
