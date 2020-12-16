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
    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var label: UILabel!
    @IBOutlet weak var letsGoButton: UIButton!
    @IBOutlet weak var imageButton: UIButton!
    
    var lottieAnimation: AnimationView?
    var version: OnboardingCardVersion = .v1

    static func create() -> HomeGameOnboardingCardView {
        let view = Bundle.main.loadViewFromNib() as HomeGameOnboardingCardView
        
        let lastVersion = UserDefaults.standard.integer(forKey: UserDefaultKeys.gameOnboardingCardVersion)
        
        if let cardVersion = OnboardingCardVersion(rawValue: lastVersion) {
            view.version = cardVersion.next()
        }
        
        view.styleViews()
        
        UserDefaults.standard.setValue(view.version.rawValue, forKey: UserDefaultKeys.gameOnboardingCardVersion)
        
        return view
    }
    
    func styleViews() {
        layer.cornerRadius = 10
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        clippingView.layer.cornerRadius = 10
        
        title.textColor = .deepGray
        label.textColor = .deepGray
        label.font = SystemFont.regular.of(textStyle: .footnote)
        
        var image: UIImage
        switch version {
        case .v1:
            image = UIImage(named: "img_gamification_home_v1")!
            title.text = NSLocalizedString("Join BGE’s Play-n-Save Pilot!", comment: "")
            label.text = NSLocalizedString("Save on your bill with personalized insights, tips and quizzes.", comment: "")
        case .v2:
            image = UIImage(named: "img_gamification_home_v2")!
            title.text = NSLocalizedString("BGE has a gift for you!", comment: "")
            label.text = NSLocalizedString("Save on your bill with personalized insights, tips and quizzes.", comment: "")
        }

        let aspectRatio = image.size.height / image.size.width
        
        imageButton.setImage(image, for: .normal)
        imageButton.heightAnchor.constraint(equalTo: clippingView.widthAnchor, multiplier: aspectRatio, constant: 0.0).isActive = true
        
        letsGoButton.tintColor = .actionBlue
        letsGoButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        letsGoButton.titleLabel?.text = NSLocalizedString("Let's Go!", comment: "")
    }
}

public enum OnboardingCardVersion: Int {
    case v1 = 1
    case v2 = 2
    
    func next() -> OnboardingCardVersion {
        switch self {
        case .v1:
            return .v2
        case .v2:
            return .v1
        }
    }
}
