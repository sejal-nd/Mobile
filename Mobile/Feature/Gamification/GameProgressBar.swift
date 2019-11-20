//
//  GameProgressBar.swift
//  Mobile
//
//  Created by Marc Shilling on 11/20/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class GameProgressBar: UIView {
    
    @IBOutlet weak var innerBackgroundView: UIView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressWidthConstraint: NSLayoutConstraint!
    
    var pointsPerLevel = 16
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func instantiate() {
        layer.cornerRadius = 10
        
        innerBackgroundView.layer.cornerRadius = 6
        innerBackgroundView.backgroundColor = .softGray
        
        progressView.layer.cornerRadius = 6
        progressView.backgroundColor = .bgeGreen
        
        progressWidthConstraint.constant = 0
    }
    
}
