//
//  LoadingIndicator.swift
//  Mobile
//
//  Created by Marc Shilling on 5/4/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Lottie
import UIKit

class LoadingIndicator: UIView {
    
    private var lottieAnimationView: LottieAnimationView?
    
    let bag = DisposeBag()

    @IBInspectable
    public var isStormMode: Bool = false {
        didSet {
            playAnimation()
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
    
    private func playAnimation() {
        lottieAnimationView?.removeFromSuperview()
        
        if isStormMode {
            lottieAnimationView = LottieAnimationView(name: "ellipses_loading_white")
        } else {
            lottieAnimationView = LottieAnimationView(name: "ellipses_loading")
        }

        lottieAnimationView!.frame.size = CGSize(width: 60, height: 12)
        lottieAnimationView!.loopMode = .loop
        lottieAnimationView!.backgroundBehavior = .pauseAndRestore
        lottieAnimationView!.play()
        
        addSubview(lottieAnimationView!)
        
        // make accessibility label for loading animation - and make it the only thing tappable
        lottieAnimationView!.isAccessibilityElement = true
        lottieAnimationView!.accessibilityLabel = NSLocalizedString("Loading", comment: "")
        lottieAnimationView!.accessibilityViewIsModal = true
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
