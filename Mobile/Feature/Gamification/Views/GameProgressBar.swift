//
//  GameProgressBar.swift
//  Mobile
//
//  Created by Marc Shilling on 11/20/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

enum SetPointsResult {
    case halfWay, levelUp
}

class GameProgressBar: UIView {
    
    @IBOutlet weak var innerBackgroundView: UIView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressWidthConstraint: NSLayoutConstraint!
    
    private var pointsPerLevel: Double = 16
    private var currentPoints: Double = 0
    
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
    
    private func setProgressWidth(_ progressWidth: CGFloat, animated: Bool, onComplete: ((Bool) -> Void)?) {
        let duration  = animated ? 1.0 : 0.0
        self.layoutIfNeeded()
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: {
            self.progressWidthConstraint.constant = progressWidth
            self.layoutIfNeeded()
        }, completion: onComplete)
    }
    
    
    func setPoints(_ points: Double, animated: Bool = true) -> SetPointsResult? {
        let totalBarWidth = innerBackgroundView.frame.size.width
        let currentLevelProgress = currentPoints.truncatingRemainder(dividingBy: pointsPerLevel)
        let desiredLevelProgress = points.truncatingRemainder(dividingBy: pointsPerLevel)
        let currentProgressWidth = (CGFloat(currentLevelProgress) / CGFloat(pointsPerLevel)) * totalBarWidth
        let desiredProgressWidth = (CGFloat(desiredLevelProgress) / CGFloat(pointsPerLevel)) * totalBarWidth
        
        var toReturn: SetPointsResult?
        if points > currentPoints && points - currentPoints <= pointsPerLevel {
            if desiredProgressWidth <= currentProgressWidth {
                toReturn = .levelUp
                setProgressWidth(totalBarWidth, animated: animated) { [weak self] _ in
                    self?.progressWidthConstraint.constant = 0
                    self?.setProgressWidth(desiredProgressWidth, animated: animated, onComplete: nil)
                }
            } else {
                if currentProgressWidth < totalBarWidth / 2 && desiredProgressWidth >= totalBarWidth / 2 {
                    toReturn = .halfWay
                }
                setProgressWidth(desiredProgressWidth, animated: animated, onComplete: nil)
            }
        } else {
            setProgressWidth(desiredProgressWidth, animated: false, onComplete: nil)
        }
        
        currentPoints = points
        return toReturn
    }
    
}
