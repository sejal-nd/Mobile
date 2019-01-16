//
//  LoadingIndicator.swift
//  Mobile
//
//  Created by Marc Shilling on 5/4/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Lottie

class LoadingIndicator: UIView {
    
    private var lottieAnimationView: LOTAnimationView?

    @IBInspectable
    public var isStormMode: Bool = false {
        didSet {
            lottieAnimationView?.removeFromSuperview()
            
            if isStormMode {
                lottieAnimationView = LOTAnimationView(name: "ellipses_loading_white")
            } else {
                lottieAnimationView = LOTAnimationView(name: "ellipses_loading")
            }
            guard let lottieAnimationView = lottieAnimationView else { return }
            
            lottieAnimationView.frame.size = CGSize(width: 60, height: 12)
            lottieAnimationView.loopAnimation = true
            lottieAnimationView.play()
            
            addSubview(lottieAnimationView)
            
            //make accessibility label for loading animation - and make it the only thing tappable
            lottieAnimationView.isAccessibilityElement = true
            lottieAnimationView.accessibilityLabel = "Loading"
            lottieAnimationView.accessibilityViewIsModal = true
        }
    }
    
    
    init() {
        super.init(frame: .zero)
        
        commonInit()
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
        backgroundColor = .clear
        
        // Triggers Initial DidSet
        isStormMode = false
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 60, height: 12)
    }
    
    override var isHidden: Bool {
        didSet {
            if isHidden {
                lottieAnimationView?.accessibilityViewIsModal = false
                lottieAnimationView?.isAccessibilityElement = false
                lottieAnimationView?.pause()
            } else {
                lottieAnimationView?.accessibilityViewIsModal = true
                lottieAnimationView?.isAccessibilityElement = true
                lottieAnimationView?.play()
            }
        }
    }
}

import RxSwift
import RxCocoa

extension Reactive where Base: LoadingIndicator {
    
    var isAnimating: Binder<Bool> {
        return Binder(base) { loadingIndicator, active in
            loadingIndicator.isHidden = !active
        }
    }
    
}
