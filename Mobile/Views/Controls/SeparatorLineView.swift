//
//  SeparatorLineView.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class SeparatorLineView: UIView {

    var leadingConstraint: NSLayoutConstraint!
    
    let internalLine = UIView(frame: .zero)
    
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
        self.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        
        addSubview(internalLine)
        
        internalLine.translatesAutoresizingMaskIntoConstraints = false
        leadingConstraint = internalLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
        leadingConstraint.isActive = true
        
        internalLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        internalLine.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        internalLine.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        internalLine.backgroundColor = .accentGray
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 312, height: 1)
    }
    
    func setHeight(_ height: CGFloat) {
        self.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
    
    func setColor(_ color: UIColor) {
        self.internalLine.backgroundColor = color
    }
    
    static func create(leadingSpace: CGFloat? = nil) -> SeparatorLineView {
        let view = SeparatorLineView(frame: .zero)
        
        if let leadingSpace = leadingSpace {
            view.removeConstraint(view.leadingConstraint)
            
            view.leadingConstraint = view.internalLine.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingSpace)
            view.leadingConstraint.isActive = true
        }
        
        return view
    }
}
