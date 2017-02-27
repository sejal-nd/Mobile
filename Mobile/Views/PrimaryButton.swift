//
//  LoginButton.swift
//  Mobile
//
//  Created by Marc Shilling on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import Lottie

class PrimaryButton: UIButton {
    
    var loadingAnimationView = LOTAnimationView.animationNamed("loading")
    var checkmarkAnimationView = LOTAnimationView.animationNamed("checkmark")
    var restoreTitle = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .buttonBackgroundNormalColor

        titleLabel!.font = UIFont.boldSystemFont(ofSize: 20)
        setTitleColor(.white, for: .normal)
        setTitleColor(UIColor.white.withAlphaComponent(0.8), for: .highlighted)
        setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // If button is not full width, add rounded corners
        if frame.size.width != UIScreen.main.bounds.size.width {
            layer.cornerRadius = 2
        }
    }
    
    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            if newValue {
                backgroundColor = .buttonBackgroundHighlightColor
            }
            else {
                backgroundColor = .buttonBackgroundNormalColor
            }
            super.isHighlighted = newValue
        }
    }
    
    override var isEnabled: Bool {
        get {
            return super.isEnabled
        }
        set {
            if newValue {
                backgroundColor = .buttonBackgroundNormalColor
            } else {
                backgroundColor = .buttonBackgroundDisabledColor
            }
            super.isEnabled = newValue
        }
    }
    
    func setLoading() {
        restoreTitle = currentTitle!
        setTitle("", for: .normal)
        
        let animationWidth = frame.size.height - 8
        let animationRect = CGRect(x: (frame.size.width / 2) - (animationWidth / 2), y: 4, width: animationWidth, height: animationWidth)
        
        loadingAnimationView!.frame = animationRect
        loadingAnimationView!.loopAnimation = true
        addSubview(loadingAnimationView!)
        loadingAnimationView!.play()
    }
    
    func setSuccess(animationCompletion: @escaping (Void) -> Void) {
        loadingAnimationView!.removeFromSuperview()
        
        let animationWidth = frame.size.height - 8
        let animationRect = CGRect(x: (frame.size.width / 2) - (animationWidth / 2), y: 4, width: animationWidth, height: animationWidth)
        
        checkmarkAnimationView!.frame = animationRect
        addSubview(checkmarkAnimationView!)
        checkmarkAnimationView!.play(completion: { (finished) in
            animationCompletion()
        })
    }
    
    func setFailure() {
        loadingAnimationView!.removeFromSuperview()
        
        setTitle(restoreTitle, for: .normal)
    }
}
