//
//  BillAlertBannerView.swift
//  Mobile
//
//  Created by Sam Francis on 8/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import Lottie

class BillAlertBannerView: UIView {
    
    @IBOutlet weak var iconView: UIView!
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var label: UILabel!
    
    var alertLottieAnimation = LOTAnimationView(name: "alert_icon")

    override func awakeFromNib() {
        super.awakeFromNib()
        
        label.font = OpenSans.regular.of(textStyle: .subheadline)
        iconView.superview?.bringSubviewToFront(iconView)
        iconView.addShadow(color: .black, opacity: 0.3, offset: .zero, radius: 3)
        
        animationView.isAccessibilityElement = true
        animationView.accessibilityLabel = NSLocalizedString("Alert", comment: "")
        
        // Here lies the reason for this class' existence. Order of `accessibilityElements`
        accessibilityElements = [animationView, label] as [UIView]
    }
    
    func resetAnimation() {
        alertLottieAnimation.removeFromSuperview()
        alertLottieAnimation = LOTAnimationView(name: "alert_icon")
        alertLottieAnimation.frame = CGRect(x: 0, y: 0, width: animationView.frame.width, height: animationView.frame.height)
        alertLottieAnimation.contentMode = .scaleAspectFill
        animationView.addSubview(self.alertLottieAnimation)
        alertLottieAnimation.play()
    }
}

import RxSwift
import RxCocoa

extension Reactive where Base: BillAlertBannerView {
    
    /// Bindable sink for `resetAnimation` method.
    var resetAnimation: Binder<Void> {
        return Binder(base) { view, _ in
            view.resetAnimation()
        }
    }
    
}
