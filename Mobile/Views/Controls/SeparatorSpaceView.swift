//
//  SeparatorSpaceView.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

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
        self.translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = self.heightAnchor.constraint(equalToConstant: 10.0)
        heightConstraint.priority = 999
        heightConstraint.isActive = true
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 312, height: 10)
    }
    
    static func create(_ heightSpace: CGFloat? = nil) -> SeparatorSpaceView {
        let view = SeparatorSpaceView(frame: .zero)
        
        if let heightSpace = heightSpace {
            view.removeConstraint(view.heightConstraint)
            
            view.heightConstraint = view.heightAnchor.constraint(equalToConstant: heightSpace)
            view.heightConstraint.priority = 999
            view.heightConstraint.isActive = true
        }
        
        return view
    }
}
