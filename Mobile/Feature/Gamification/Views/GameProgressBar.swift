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
    
    private var pointsPerLevel = 16
    
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
    
    func setPoints(_ points: Int, animated: Bool) {
        var levelProgress: Int
        if points == pointsPerLevel {
            levelProgress = pointsPerLevel // Level up
        } else {
            levelProgress = points % pointsPerLevel
        }
        
        let totalBarWidth = innerBackgroundView.frame.size.width
        let progressWidth = (CGFloat(levelProgress) / CGFloat(pointsPerLevel)) * totalBarWidth
        

        
        let animateToFinalPosition = {
            self.layoutIfNeeded()
            UIView.animate(withDuration: animated ? 1 : 0, delay: 0, options: [.curveEaseOut], animations: {
                self.progressWidthConstraint.constant = progressWidth
                self.layoutIfNeeded()
            }, completion: nil)
        }
        
        if progressWidth < progressView.frame.size.width {
            UIView.animate(withDuration: animated ? 1 : 0, delay: 0, options: [.curveEaseOut], animations: {
                self.progressWidthConstraint.constant = totalBarWidth
                self.layoutIfNeeded()
            }, completion: { _ in
                self.progressWidthConstraint.constant = 0
                animateToFinalPosition()
            })
        } else {
            animateToFinalPosition()
        }

    }
    
}
