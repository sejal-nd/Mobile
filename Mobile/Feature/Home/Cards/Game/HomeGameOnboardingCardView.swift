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
    @IBOutlet private weak var imageView: UIImageView!
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
        
        loopImageTransition()
    }
    
    func loopImageTransition() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
            self.imageView.image = #imageLiteral(resourceName: "onboarding_card_coin_reveal.pdf")
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                self.imageView.image = #imageLiteral(resourceName: "onboarding_card_coin.pdf")
                self.loopImageTransition()
            }
        }
    }
}
