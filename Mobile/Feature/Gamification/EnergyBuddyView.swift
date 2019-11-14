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
    
    @IBOutlet weak var energyBuddyContainerView: UIView!
    @IBOutlet weak var energyBuddyContainerTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var energyBuddyBodyLottieView: UIView!
    @IBOutlet weak var energyBuddyFaceLottieView: UIView!
    @IBOutlet weak var energyBuddyParticleLottieView: UIView!
    
    var bodyAnimation: LOTAnimationView?
    var faceAnimation: LOTAnimationView?
    var particleAnimation: LOTAnimationView?

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
        
        setDefaultAnimations()
    }
    
    func bounce() {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.energyBuddyContainerTopConstraint.constant = 25
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func setDefaultAnimations() {
        bodyAnimation = LOTAnimationView(name: "buddy_body")
        bodyAnimation!.frame.size = energyBuddyBodyLottieView.frame.size
        bodyAnimation!.loopAnimation = true
        bodyAnimation!.contentMode = .scaleAspectFit
        energyBuddyBodyLottieView.addSubview(bodyAnimation!)
        bodyAnimation!.play()
        
        faceAnimation = LOTAnimationView(name: "buddy_face_normal")
        faceAnimation!.frame.size = energyBuddyFaceLottieView.frame.size
        faceAnimation!.loopAnimation = true
        faceAnimation!.contentMode = .scaleAspectFit
        energyBuddyFaceLottieView.addSubview(faceAnimation!)
        faceAnimation!.play()
        
//        particleAnimation = LOTAnimationView(name: "buddy_particles_sparkles")
//        particleAnimation!.frame.size = energyBuddyParticleLottieView.frame.size
//        particleAnimation!.loopAnimation = true
//        particleAnimation!.contentMode = .scaleAspectFit
//        energyBuddyParticleLottieView.addSubview(particleAnimation!)
//        particleAnimation!.play()
    }

}
