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
    
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var label: UILabel!
    
    var alertLottieAnimation = AnimationView(name: "alert_icon")

    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.cornerRadius = 10
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        
        label.textColor = .deepGray
        label.font = OpenSans.regular.of(textStyle: .footnote)
        
        animationView.isAccessibilityElement = true
        animationView.accessibilityLabel = NSLocalizedString("Alert", comment: "")
        
        // Here lies the reason for this class' existence. Order of `accessibilityElements`
        accessibilityElements = [animationView, label] as [UIView]
    }
    
    func resetAnimation() {
        alertLottieAnimation.removeFromSuperview()
        alertLottieAnimation = AnimationView(name: "alert_icon")
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
