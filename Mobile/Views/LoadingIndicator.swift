//
//  LoadingIndicator.swift
//  Mobile
//
//  Created by Marc Shilling on 5/4/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Lottie
import RxSwift
import RxCocoa

class LoadingIndicator: UIView {
    
    private var lottieAnimationView = LOTAnimationView(name: "ellipses_loading")
    
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
        
        lottieAnimationView!.frame.size = CGSize(width: 60, height: 12)
        lottieAnimationView!.loopAnimation = true
        lottieAnimationView!.play()
        
        addSubview(lottieAnimationView!)
        
        //make accessibility label for loading animation - and make it the only thing tappable
        lottieAnimationView!.isAccessibilityElement = true;
        lottieAnimationView!.accessibilityLabel = "Loading";
        lottieAnimationView!.accessibilityViewIsModal = true;
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 60, height: 12)
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

extension Reactive where Base: LoadingIndicator {
    
    var isAnimating: UIBindingObserver<Base, Bool> {
        return UIBindingObserver(UIElement: self.base) { loadingIndicator, active in
            loadingIndicator.isHidden = !active
        }
    }
    
}
