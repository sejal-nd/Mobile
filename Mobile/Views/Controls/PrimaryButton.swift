//
//  PrimaryButton.swift
//  Mobile
//
//  Created by Marc Shilling on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import Lottie

class PrimaryButton: UIButton {
    
    var loadingAnimationView = LOTAnimationView(name: "loading")
    var checkmarkAnimationView = LOTAnimationView(name: "checkmark")
    var restoreTitle: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .ctaBlue
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        titleLabel?.font = SystemFont.bold.of(textStyle: .headline)
        setTitleColor(.white, for: .normal)
        setTitleColor(UIColor.white.withAlphaComponent(0.8), for: .highlighted)
        setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        layer.cornerRadius = 10.0
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = UIColor(red: 0/255, green: 38/255, blue: 88/255, alpha: 1) // Special case color - do not change
            } else {
                backgroundColor = .ctaBlue
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? .ctaBlue: .middleGray
            accessibilityTraits = isEnabled ? .button : [.button, .notEnabled]
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
