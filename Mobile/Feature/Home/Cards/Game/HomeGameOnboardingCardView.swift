//
//  HomeGameOnboardingCardView.swift
//  Mobile
//
//  Created by Marc Shilling on 11/12/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import Lottie

class HomeGameOnboardingCardView: UIView {
    
    @IBOutlet private weak var clippingView: UIView!
    @IBOutlet private weak var lottieView: UIView!
    @IBOutlet private weak var label: UILabel!
    @IBOutlet weak var letsGoButton: UIButton!
    
    var lottieAnimation: AnimationView?

    static func create() -> HomeGameOnboardingCardView {
        let view = Bundle.main.loadViewFromNib() as HomeGameOnboardingCardView
        view.styleViews()
        return view
    }
    
    func styleViews() {
        layer.cornerRadius = 10
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        clippingView.layer.cornerRadius = 10
        
        label.textColor = .deepGray
        label.font = SystemFont.regular.of(textStyle: .footnote)
        label.text = NSLocalizedString("Unlock data and insights to help you save money and the environment at the same time!", comment: "")
        
        letsGoButton.tintColor = .actionBlue
        letsGoButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        letsGoButton.titleLabel?.text = NSLocalizedString("Let's Go!", comment: "")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        lottieAnimation?.stop()
        lottieAnimation?.removeFromSuperview()
        
        lottieAnimation = AnimationView(name: "home_onboarding_card")
        lottieAnimation!.frame = CGRect(x: 0, y: 0, width: lottieView.frame.size.width, height: lottieView.frame.size.height)
        lottieAnimation!.loopMode = .loop
        lottieAnimation!.contentMode = .scaleAspectFit
        lottieView.addSubview(lottieAnimation!)
        lottieAnimation!.play()
    }
}
