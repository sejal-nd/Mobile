//
//  StateAnimationView.swift
//  EUMobile
//
//  Created by Gina Mullins on 1/10/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import UIKit
import Lottie

class StateAnimationView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet weak var progressAnimationContainer: UIView!
    @IBOutlet weak var errorImageView: UIImageView!
    
    var status: OutageTracker.Status = .none
    var progressAnimation = AnimationView(name: "ot_reported")
    var isStormMode: Bool {
        return StormModeStatus.shared.isOn
    }
    var animationName: String {
        switch status {
            case .reported:
                return isStormMode ? "outage_reported_sm" : "outage_reported"
            case .assigned:
                return isStormMode ? "outage_assigned_sm" : "outage_assigned"
            case .enRoute:
                return isStormMode ? "outage_enroute_sm" : "outage_enroute"
            case .onSite:
                return isStormMode ? "outage_onsite_sm" : "outage_onsite"
            case .restored:
                return isStormMode ? "outage_on_sm" : "outage_on"
            default:
                return ""
        }
    }
    
    func configure(withStatus status: OutageTracker.Status) {
        progressAnimationContainer.isHidden = true
        errorImageView.isHidden = true
        if status == .none {
            errorImageView.isHidden = false
        } else {
            self.status = status
            setUpProgressAnimation(animName: animationName)
            progressAnimationContainer.isHidden = false
        }
    }


    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(self.className, owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        progressAnimationContainer.isHidden = true
        errorImageView.isHidden = true
    }
}

extension StateAnimationView {
    
    // MARK - Lottie Animation
    
    func setUpProgressAnimation(animName: String) {
        progressAnimation.removeFromSuperview()
        progressAnimation = AnimationView(name: animName)
        
        progressAnimation.frame = CGRect(x: 0, y: 1, width: progressAnimationContainer.frame.size.width, height: progressAnimationContainer.frame.size.height)
        progressAnimation.loopMode = .loop
        progressAnimation.backgroundBehavior = .pauseAndRestore
        progressAnimation.contentMode = .scaleAspectFill
        
        progressAnimationContainer.addSubview(progressAnimation)
        
        progressAnimation.play()
    }
}

