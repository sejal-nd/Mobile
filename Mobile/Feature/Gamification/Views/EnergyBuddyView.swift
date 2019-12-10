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
    
    @IBOutlet weak var taskIndicatorView: UIView!
    @IBOutlet weak var taskIndicatorLottieView: UIView!
    
    @IBOutlet weak var energyBuddyContainerView: UIView!
    @IBOutlet weak var energyBuddyContainerTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var energyBuddyBodyLottieView: UIView!
    @IBOutlet weak var energyBuddyFaceLottieView: UIView!
    @IBOutlet weak var energyBuddyParticleLottieView: UIView!
    
    var bodyAnimation: AnimationView?
    var faceAnimation: AnimationView?
    var particleAnimation: AnimationView?
    var taskIndicatorAnimation: AnimationView?
    
    private var currentTask: GameTaskType?
    
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
        
        taskIndicatorView.isHidden = true
        
        updateSky()
    }
    
    func updateSky() {
        skyImageView.image = Date.now.skyImageForCurrentTime
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
        
        setTaskIndicator(currentTask)
        
        if resetBounce {
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 1, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.energyBuddyContainerTopConstraint.constant = 10
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    func stopAnimations() {
        bodyAnimation?.stop()
        faceAnimation?.stop()
        particleAnimation?.stop()
        taskIndicatorAnimation?.stop()
        energyBuddyContainerTopConstraint.constant = 0
    }
    
    func playHappyAnimation() {
        faceAnimation?.stop()
        faceAnimation?.removeFromSuperview()
        faceAnimation = AnimationView(name: "buddy_face_happy")
        faceAnimation!.frame.size = energyBuddyFaceLottieView.frame.size
        faceAnimation!.contentMode = .scaleAspectFit
        energyBuddyFaceLottieView.addSubview(faceAnimation!)
        faceAnimation!.play { [weak self] finished in
            if finished {
                self?.playDefaultAnimations(resetBounce: false)
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
        faceAnimation!.play { [weak self] finished in
            if finished {
                self?.playDefaultAnimations(resetBounce: false)
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
    
    func showWelcomeMessage() {
        let randomInt = Int.random(in: 0...welcomeMessages.count)
        if randomInt < welcomeMessages.count {
            speechBubbleLabel.text = welcomeMessages[randomInt]
        } else {
            speechBubbleLabel.text = Date.now.localizedGameGreeting
        }
        
        animateSpeechBubble()
    }
    
    func showHalfWayMessage() {
        let randomInt = Int.random(in: 0..<halfWayMessages.count)
        speechBubbleLabel.text = halfWayMessages[randomInt]
        
        animateSpeechBubble()
    }
    
    func showLevelUpMessage() {
        let randomInt = Int.random(in: 0..<levelUpMessages.count)
        speechBubbleLabel.text = levelUpMessages[randomInt]
        
        animateSpeechBubble()
    }
    
    // Pass `nil` to hide indicator
    func setTaskIndicator(_ type: GameTaskType?) {
        currentTask = type
        
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
