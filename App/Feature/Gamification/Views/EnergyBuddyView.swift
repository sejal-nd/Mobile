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
    
    @IBOutlet weak var confettiLottieView: UIView!
    
    @IBOutlet weak var energyBuddyContainerView: UIView!
    @IBOutlet weak var energyBuddyContainerTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var energyBuddyBodyLottieView: UIView!
    @IBOutlet weak var energyBuddyFaceLottieView: UIView!
    @IBOutlet weak var energyBuddyHatImageView: UIImageView!
    @IBOutlet weak var energyBuddyAccessoryImageView: UIImageView!
    @IBOutlet weak var energyBuddyParticleLottieView: UIView!
    
    @IBOutlet weak var speechBubbleContainerView: UIView!
    @IBOutlet weak var speechBubbleView: UIView!
    @IBOutlet weak var speechBubbleLabel: UILabel!
    
    @IBOutlet weak var taskIndicatorView: UIView!
    @IBOutlet weak var taskIndicatorLottieView: UIView!
    
    var confettiAnimation: AnimationView?
    var bodyAnimation: AnimationView?
    var faceAnimation: AnimationView?
    var particleAnimation: AnimationView?
    var taskIndicatorAnimation: AnimationView?
    
    var speechBubbleAnimator: UIViewPropertyAnimator?
    var welcomeMessages = [
        NSLocalizedString("Welcome back!", comment: ""),
        NSLocalizedString("It's great to see you!", comment: ""),
        NSLocalizedString("Hello!", comment: "")
    ]
    let halfWayMessages = [
        NSLocalizedString("Almost there!", comment: ""),
        NSLocalizedString("Nice job!", comment: "")
    ]
    let levelUpMessages = [
        NSLocalizedString("You did it!", comment: ""),
        NSLocalizedString("Great job!", comment: ""),
        NSLocalizedString("Congrats!", comment: "")
    ]
    let newGiftAppliedMessages = [
        NSLocalizedString("Thanks!", comment: ""),
        NSLocalizedString("Wow, this is great!", comment: ""),
        NSLocalizedString("Wow!", comment: "")
    ]
    let firstTaskMessage = NSLocalizedString("Well Done!", comment: "")
    
    var confettiEnabled = false

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
        speechBubbleLabel.textColor = .neutralDark
        speechBubbleLabel.font = ExelonFont.semibold.of(textStyle: .headline)
        speechBubbleContainerView.alpha = 0
        
        taskIndicatorView.isHidden = true
        
        updateBuddy()
    }
    
    func updateBuddy() {
        let isNighttime = Date.now.isNighttime
        
        skyImageView.image = isNighttime ? #imageLiteral(resourceName: "img_bgsky_night.pdf") : #imageLiteral(resourceName: "img_bgsky_day.pdf")
        
        if let selectedBgId = UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedBackground),
            let selectedBg = GiftInventory.shared.gift(withId: selectedBgId) {
            backgroundImageView.image = isNighttime ? selectedBg.nightImage : selectedBg.dayImage
        } else {
            backgroundImageView.image = nil
        }
        
        if let selectedHatId = UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedHat),
            let selectedHat = GiftInventory.shared.gift(withId: selectedHatId) {
            energyBuddyHatImageView.image = selectedHat.image
        } else {
            energyBuddyHatImageView.image = nil
        }
        
        if let selectedAccessoryId = UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedAccessory),
            let selectedAccessory = GiftInventory.shared.gift(withId: selectedAccessoryId) {
            energyBuddyAccessoryImageView.image = selectedAccessory.image
        } else {
            energyBuddyAccessoryImageView.image = nil
        }        
    }
    
    func stopAnimations() {
        confettiAnimation?.stop()
        bodyAnimation?.stop()
        faceAnimation?.stop()
        particleAnimation?.stop()
        taskIndicatorAnimation?.stop()
        energyBuddyContainerTopConstraint.constant = -10
    }
    
    func playConfettiAnimation() {
        confettiEnabled = true
        
        confettiAnimation?.stop()
        confettiAnimation?.removeFromSuperview()
        confettiAnimation = AnimationView(name: "confetti")
        confettiAnimation!.frame.size = confettiLottieView.frame.size
        confettiAnimation!.contentMode = .scaleAspectFit
        confettiAnimation!.loopMode = .loop
        confettiAnimation!.backgroundBehavior = .pauseAndRestore
        confettiLottieView.addSubview(confettiAnimation!)
        confettiAnimation!.play()
    }
    
    func playDefaultAnimations(resetBounce: Bool = true) {
        bodyAnimation?.stop()
        bodyAnimation?.removeFromSuperview()
        bodyAnimation = AnimationView(name: "buddy_body")
        bodyAnimation!.frame.size = energyBuddyBodyLottieView.frame.size
        bodyAnimation!.contentMode = .scaleAspectFit
        bodyAnimation!.loopMode = .loop
        energyBuddyBodyLottieView.addSubview(bodyAnimation!)
        bodyAnimation!.play()
        
        playDefaultFaceAnimation()
        
        particleAnimation?.stop()
        particleAnimation?.removeFromSuperview()
        
        if confettiEnabled {
            playConfettiAnimation()
        }
        
        if resetBounce {
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 1, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.energyBuddyContainerTopConstraint.constant = 0
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    private func playDefaultFaceAnimation() {
        faceAnimation?.stop()
        faceAnimation?.removeFromSuperview()
        faceAnimation = AnimationView(name: "buddy_face_normal")
        faceAnimation!.frame.size = energyBuddyFaceLottieView.frame.size
        faceAnimation!.contentMode = .scaleAspectFit
        faceAnimation!.loopMode = .loop
        energyBuddyFaceLottieView.addSubview(faceAnimation!)
        faceAnimation!.play()
    }

    func playHappyAnimation() {
        faceAnimation?.stop()
        faceAnimation?.removeFromSuperview()
        faceAnimation = AnimationView(name: "buddy_face_happy")
        faceAnimation!.frame.size = energyBuddyFaceLottieView.frame.size
        faceAnimation!.contentMode = .scaleAspectFit
        energyBuddyFaceLottieView.addSubview(faceAnimation!)
        faceAnimation!.play { finished in
            if finished {
                self.playDefaultFaceAnimation()
            }
        }
    }
    
    func playSuperHappyAnimation(withSparkles sparkles: Bool = false, withHearts hearts: Bool = false) {
        faceAnimation?.stop()
        faceAnimation?.removeFromSuperview()
        faceAnimation = AnimationView(name: "buddy_face_happy_bounce")
        faceAnimation!.frame.size = energyBuddyFaceLottieView.frame.size
        faceAnimation!.contentMode = .scaleAspectFit
        energyBuddyFaceLottieView.addSubview(faceAnimation!)
        faceAnimation!.play { finished in
            if finished {
                self.playDefaultFaceAnimation()
            }
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
    
    private func animateSpeechBubble() {
        speechBubbleAnimator?.stopAnimation(true)
        speechBubbleContainerView.alpha = 0
        
        speechBubbleAnimator = UIViewPropertyAnimator(duration: 0.33, curve: .linear, animations: {
            self.speechBubbleContainerView.alpha = 1
        })
        speechBubbleAnimator?.addCompletion({ _ in
            self.speechBubbleAnimator = UIViewPropertyAnimator(duration: 0.33, curve: .linear, animations: {
                self.speechBubbleContainerView.alpha = 0
            })
            self.speechBubbleAnimator?.startAnimation(afterDelay: 3)
        })
        speechBubbleAnimator?.startAnimation()
    }
    
    func showWelcomeMessage(isFirstTimeSeeingBuddy: Bool = false) {
        if isFirstTimeSeeingBuddy { // Ensure he doesn't say "Welcome Back!"
            speechBubbleLabel.text = NSLocalizedString("Hello!", comment: "")
        } else {
            let randomInt = Int.random(in: 0...welcomeMessages.count)
            if randomInt < welcomeMessages.count {
                speechBubbleLabel.text = welcomeMessages[randomInt]
            } else {
                speechBubbleLabel.text = Date.now.localizedGameGreeting
            }
        }
        
        animateSpeechBubble()
    }
    
    func showHalfWayMessage() {
        let randomInt = Int.random(in: 0..<halfWayMessages.count)
        speechBubbleLabel.text = halfWayMessages[randomInt]
        
        animateSpeechBubble()
    }
    
    func showLevelUpMessage(isFirstTimeSeeingBuddy: Bool = false) {
        if isFirstTimeSeeingBuddy {
            speechBubbleLabel.text = firstTaskMessage
        } else {
            let randomInt = Int.random(in: 0..<levelUpMessages.count)
            speechBubbleLabel.text = levelUpMessages[randomInt]
        }
        
        animateSpeechBubble()
    }
    
    func showNewGiftAppliedMessage(forGift gift: Gift) {
        if let customMessage = gift.customMessage {
            speechBubbleLabel.text = customMessage
        } else {
            let randomInt = Int.random(in: 0..<newGiftAppliedMessages.count)
            speechBubbleLabel.text = newGiftAppliedMessages[randomInt]
        }
        
        animateSpeechBubble()
    }
    
    // Pass `nil` to hide indicator
    func setTaskIndicator(_ type: GameTaskType?) {
        taskIndicatorAnimation?.stop()
        taskIndicatorAnimation?.removeFromSuperview()
        
        guard let taskType = type else {
            taskIndicatorView.isHidden = true
            return
        }
        
        var lottieFileName: String
        switch taskType {
        case .tip:
            lottieFileName = "message_bubble_tip"
        case .quiz:
            lottieFileName = "message_bubble_quiz"
        default:
            lottieFileName = "message_bubble_unique"
        }
        
        taskIndicatorAnimation = AnimationView(name: lottieFileName)
        taskIndicatorAnimation!.frame.size = taskIndicatorLottieView.frame.size
        taskIndicatorAnimation!.contentMode = .scaleAspectFit
        taskIndicatorAnimation!.loopMode = .loop
        taskIndicatorAnimation!.backgroundBehavior = .pauseAndRestore
        taskIndicatorLottieView.addSubview(taskIndicatorAnimation!)
        taskIndicatorAnimation!.play()
        
        taskIndicatorView.isHidden = false
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
    
    var isNighttime: Bool {
        let components = Calendar.current.dateComponents([.hour], from: self)
        if let hour = components.hour {
            if hour <= 6 || hour >= 18 { // Night image displays between 6pm and 6am
                return true
            }
        }
        return false
    }
    
}
