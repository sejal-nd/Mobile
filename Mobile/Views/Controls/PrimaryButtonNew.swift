//
//  PrimaryButtonNew.swift
//  Mobile
//
//  Created by Marc Shilling on 6/24/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import Lottie

class PrimaryButtonNew: UIButton {
    
    var loadingAnimationView = LOTAnimationView(name: "loading")
    var checkmarkAnimationView = LOTAnimationView(name: "checkmark")
    var restoreTitle: String?
    
    @IBInspectable var tintWhite: Bool = false {
        didSet {
            updateTitleColors()
            updateEnabledState()
        }
    }
    
    @IBInspectable var condensed: Bool = false {
        didSet {
            titleLabel?.font = condensed ? SystemFont.semibold.of(textStyle: .subheadline) :
                SystemFont.semibold.of(textStyle: .headline)
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
        
        titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        layer.cornerRadius = frame.size.height / 2
        
        updateTitleColors()
        updateEnabledState()
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = tintWhite ? UIColor.white.withAlphaComponent(0.8) :
                    UIColor(red: 17/255, green: 57/255, blue: 112/255, alpha: 1) // Special case color - do not change
                imageView?.alpha = 0.6
            } else {
                backgroundColor = tintWhite ? .white : .actionBlue
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
            titleColor = .actionBlue
            highlightColor = .actionBlue
            disabledColor = UIColor.actionBlue.withAlphaComponent(0.5)
        } else {
            titleColor = .white
            highlightColor = UIColor.white.withAlphaComponent(0.7)
            disabledColor = UIColor.deepGray.withAlphaComponent(0.5)
        }
        
        setTitleColor(titleColor, for: .normal)
        setTitleColor(highlightColor, for: .highlighted)
        setTitleColor(disabledColor, for: .disabled)
    }
    
    private func updateEnabledState() {
        if isEnabled {
            backgroundColor = tintWhite ? .white : .actionBlue
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
        loadingAnimationView.loopAnimation = true
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
