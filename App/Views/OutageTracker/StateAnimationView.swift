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
                return isStormMode ? "SM_ReportedWhite" : "ot_reported"
            case .assigned:
                return isStormMode ? "SM_ot_assigned" : "ot_assigned"
            case .enRoute:
                return isStormMode ? "SM_ot_enroute" : "ot_enroute"
            case .onSite:
                return isStormMode ? "SM_ot_onsite" : "ot_onsite"
            case .restored:
                return isStormMode ? "SM_OnWhite" : "outage_on"
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
            setUpProgressAnimation()
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
    
    func setUpProgressAnimation() {
        progressAnimation.removeFromSuperview()
        progressAnimation = AnimationView(name: animationName)
        
        progressAnimation.frame = CGRect(x: 0, y: 1, width: progressAnimationContainer.frame.size.width, height: progressAnimationContainer.frame.size.height)
        progressAnimation.loopMode = .loop
        progressAnimation.backgroundBehavior = .pauseAndRestore
        progressAnimation.contentMode = .scaleAspectFill
        
        progressAnimationContainer.addSubview(progressAnimation)
        
        progressAnimation.play()
    }
}

