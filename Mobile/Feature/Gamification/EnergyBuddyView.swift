//
//  EnergyBuddyView.swift
//  Mobile
//
//  Created by Marc Shilling on 11/14/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import Lottie

class EnergyBuddyView: UIView {
    @IBOutlet weak private var view: UIView!
    
    // In order from back to front:
    @IBOutlet weak var skyImageView: UIImageView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var speechBubbleContainerView: UIView!
    @IBOutlet weak var speechBubbleView: UIView!
    @IBOutlet weak var speechBubbleLabel: UILabel!
    
    @IBOutlet weak var energyBuddyContainerView: UIView!
    @IBOutlet weak var energyBuddyContainerTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var energyBuddyBodyLottieView: UIView!
    @IBOutlet weak var energyBuddyFaceLottieView: UIView!
    @IBOutlet weak var energyBuddyParticleLottieView: UIView!
    
    var bodyAnimation: AnimationView?
    var faceAnimation: AnimationView?
    var particleAnimation: AnimationView?
    
    var welcomeMessages = [
        NSLocalizedString("Welcome back!", comment: ""),
        NSLocalizedString("It's great to see you!", comment: ""),
        NSLocalizedString("Hello!", comment: "")
    ]
    let fiftyPercentMessages = [
        NSLocalizedString("Almost there!", comment: ""),
        NSLocalizedString("Nice job!", comment: "")
    ]
    let levelUpMessages = [
        NSLocalizedString("You did it!", comment: ""),
        NSLocalizedString("Great job!", comment: ""),
        NSLocalizedString("Congrats!", comment: "")
    ]
    let newItemMessages = [
        NSLocalizedString("Thanks!", comment: ""),
        NSLocalizedString("Wow, this is great!", comment: ""),
        NSLocalizedString("Wow!", comment: "")
    ]

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("EnergyBuddyView", owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        
        speechBubbleView.layer.cornerRadius = 10
        speechBubbleLabel.textColor = .deepGray
        speechBubbleLabel.font = OpenSans.semibold.of(textStyle: .headline)
        speechBubbleContainerView.alpha = 0
        
        updateSky()
    }
    
    func updateSky() {
        skyImageView.image = Date().skyImageForCurrentTime
    }
    
    func playDefaultAnimations() {
        bodyAnimation?.stop()
        bodyAnimation?.removeFromSuperview()
        bodyAnimation = AnimationView(name: "buddy_body")
        bodyAnimation!.frame.size = energyBuddyBodyLottieView.frame.size
        bodyAnimation!.contentMode = .scaleAspectFit
        bodyAnimation!.loopMode = .loop
        energyBuddyBodyLottieView.addSubview(bodyAnimation!)
        bodyAnimation!.play()
        
        faceAnimation?.stop()
        faceAnimation?.removeFromSuperview()
        faceAnimation = AnimationView(name: "buddy_face_normal")
        faceAnimation!.frame.size = energyBuddyFaceLottieView.frame.size
        faceAnimation!.contentMode = .scaleAspectFit
        faceAnimation!.loopMode = .loop
        energyBuddyFaceLottieView.addSubview(faceAnimation!)
        faceAnimation!.play()
        
        particleAnimation?.stop()
        particleAnimation?.removeFromSuperview()
    }
    
    func stopAnimations() {
        bodyAnimation?.stop()
        faceAnimation?.stop()
        particleAnimation?.stop()
    }
    
    func bounce() {
        self.energyBuddyContainerTopConstraint.constant = 0
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 1, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.energyBuddyContainerTopConstraint.constant = 10
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func playHappyAnimation() {
        faceAnimation?.stop()
        faceAnimation?.removeFromSuperview()
        faceAnimation = AnimationView(name: "buddy_face_happy")
        faceAnimation!.frame.size = energyBuddyFaceLottieView.frame.size
        faceAnimation!.contentMode = .scaleAspectFit
        energyBuddyFaceLottieView.addSubview(faceAnimation!)
        faceAnimation!.play { [weak self] _ in
            self?.playDefaultAnimations()
        }
    }
    
    func playSuperHappyAnimation(withSparkles sparkles: Bool = false, withHearts hearts: Bool = false) {
        faceAnimation?.stop()
        faceAnimation?.removeFromSuperview()
        faceAnimation = AnimationView(name: "buddy_face_happy_bounce")
        faceAnimation!.frame.size = energyBuddyFaceLottieView.frame.size
        faceAnimation!.contentMode = .scaleAspectFit
        energyBuddyFaceLottieView.addSubview(faceAnimation!)
        faceAnimation!.play { [weak self] _ in
            self?.playDefaultAnimations()
        }
        
        var particleAnimationView: AnimationView?
        if sparkles {
            particleAnimationView = AnimationView(name: "buddy_particles_sparkles")
        } else if hearts {
            particleAnimationView = AnimationView(name: "buddy_particles_hearts")
        }
        if let av = particleAnimationView {
            particleAnimation = av
            particleAnimation!.frame.size = energyBuddyParticleLottieView.frame.size
            particleAnimation!.contentMode = .scaleAspectFit
            energyBuddyParticleLottieView.addSubview(particleAnimation!)
            particleAnimation!.play()
        }
    }
    
    func showWelcomeMessage() {
        let randomInt = Int.random(in: 0..<welcomeMessages.count)
        
        var greeting: String
        if randomInt < welcomeMessages.count {
            greeting = welcomeMessages[randomInt]
        } else {
            greeting = Date().localizedGameGreeting
        }
        
        speechBubbleLabel.text = greeting
        UIView.animate(withDuration: 0.33, animations: {
            self.speechBubbleContainerView.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.33, delay: 3, options: [], animations: {
                self.speechBubbleContainerView.alpha = 0
            }, completion: nil)
        })
    }

}

extension Date {
    @nonobjc var localizedGameGreeting: String {
        let components = Calendar.current.dateComponents([.hour], from: self)
        guard let hour = components.hour else { return "Greetings!" }
        
        if 4 ... 11 ~= hour {
            return NSLocalizedString("Good morning!", comment: "")
        } else if 11 ... 15 ~= hour {
            return NSLocalizedString("Good afternoon!", comment: "")
        } else {
            return NSLocalizedString("Good evening!", comment: "")
        }
    }
    
    var skyImageForCurrentTime: UIImage {
        let components = Calendar.current.dateComponents([.hour], from: self)
        if let hour = components.hour {
            if hour <= 6 || hour >= 19 { // Night image displays between 7pm and 6am
                return #imageLiteral(resourceName: "img_bgsky_night.pdf")
            }
        }
        return #imageLiteral(resourceName: "img_bgsky_day.pdf")
    }
}
