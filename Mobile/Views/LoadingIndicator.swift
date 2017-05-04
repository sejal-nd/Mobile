//
//  LoadingIndicator.swift
//  Mobile
//
//  Created by Marc Shilling on 5/4/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Lottie

class LoadingIndicator: UIView {
    
    private var lottieAnimationView = LOTAnimationView(name: "loading_blue")
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .clear
        
        lottieAnimationView!.frame.size = CGSize(width: 37, height: 37)
        lottieAnimationView!.loopAnimation = true
        lottieAnimationView!.play()
        
        addSubview(lottieAnimationView!)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 37, height: 37)
    }
    
    override var isHidden: Bool {
        didSet {
            if isHidden {
                lottieAnimationView!.pause()
            } else {
                lottieAnimationView!.play()
            }
        }
    }
}
