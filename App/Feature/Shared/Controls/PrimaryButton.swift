//
//  PrimaryButton.swift
//  Mobile
//
//  Created by Marc Shilling on 6/24/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import Lottie

class PrimaryButton: UIButton {
    
    var loadingAnimationView = AnimationView(name: "loading")
    var checkmarkAnimationView = AnimationView(name: "checkmark")
    var restoreTitle: String?
    
    @IBInspectable var tintWhite: Bool = false {
        didSet {
            updateTitleColors()
            updateEnabledState()
        }
    }
    
    @IBInspectable var condensed: Bool = false {
        didSet {
            titleLabel?.font = condensed ? .subheadlineSemibold :
                .headlineSemibold
        }
    }
    
    var hasBlueAnimations: Bool = false {
        didSet {
            loadingAnimationView = AnimationView(name: "smallcircleload_blue")
            checkmarkAnimationView = AnimationView(name: "checkmark_blue")
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        adjustsImageWhenHighlighted = false
        
        titleLabel?.font = .headlineSemibold

        updateTitleColors()
        updateEnabledState()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.size.height / 2
    }
        
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = tintWhite ? UIColor.white.withAlphaComponent(0.8) :
                    UIColor(red: 17/255, green: 57/255, blue: 112/255, alpha: 1) // Special case color - do not change
                imageView?.alpha = 0.6
            } else {
                backgroundColor = tintWhite ? .white : .primaryBlue
                imageView?.alpha = 1
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            updateEnabledState()
        }
    }
    
    private func updateTitleColors() {
        let titleColor: UIColor, highlightColor: UIColor, disabledColor: UIColor
        
        if tintWhite {
            titleColor = .primaryBlue
            highlightColor = .primaryBlue
            disabledColor = UIColor.primaryBlue.withAlphaComponent(0.5)
        } else {
            titleColor = .white
            highlightColor = UIColor.white.withAlphaComponent(0.7)
            disabledColor = UIColor.neutralDark.withAlphaComponent(0.5)
        }
        
        setTitleColor(titleColor, for: .normal)
        setTitleColor(highlightColor, for: .highlighted)
        setTitleColor(disabledColor, for: .disabled)
    }
    
    private func updateEnabledState() {
        if isEnabled {
            backgroundColor = tintWhite ? .white : .primaryBlue
            accessibilityTraits = .button
        } else {
            backgroundColor = tintWhite ? UIColor.white.withAlphaComponent(0.3) : .accentGray
            accessibilityTraits = [.button, .notEnabled]
        }
    }
    
    func setLoading() {
        restoreTitle = currentTitle!
        setTitle("", for: .normal)
        
        let animationWidth = frame.size.height - 16
        let animationRect = CGRect(x: (frame.size.width / 2) - (animationWidth / 2), y: 8, width: animationWidth, height: animationWidth)
        
        loadingAnimationView.frame = animationRect
        loadingAnimationView.loopMode = .loop
        loadingAnimationView.backgroundBehavior = .pauseAndRestore
        addSubview(loadingAnimationView)
        loadingAnimationView.play()
    }
    
    func setSuccess(animationCompletion: @escaping () -> Void) {
        setTitle("", for: .normal)
        
        loadingAnimationView.removeFromSuperview()
        
        let animationWidth = frame.size.height - 24
        let animationRect = CGRect(x: (frame.size.width / 2) - (animationWidth / 2), y: 10, width: animationWidth, height: animationWidth)
        
        checkmarkAnimationView.frame = animationRect
        addSubview(checkmarkAnimationView)
        checkmarkAnimationView.play(completion: { (finished) in
            animationCompletion()
        })
    }
    
    func reset() {
        loadingAnimationView.removeFromSuperview()
        checkmarkAnimationView.removeFromSuperview()
        
        if let title = restoreTitle {
            setTitle(title, for: .normal)
        }
    }
    
}
