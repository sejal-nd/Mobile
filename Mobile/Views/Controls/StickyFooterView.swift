//
//  StickyFooterView.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/8/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

/// UIView that contains a 1 pixel stroke pinned to the top
class StickyFooterView: UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    private func commonInit() {
        let strokeView = UIView()
        strokeView.backgroundColor = .accentGray
        addSubview(strokeView)
        
        strokeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            strokeView.topAnchor.constraint(equalTo: topAnchor),
            strokeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            strokeView.trailingAnchor.constraint(equalTo: trailingAnchor),
            strokeView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}
