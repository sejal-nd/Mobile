//
//  TutorialViewViewController.swift
//  Mobile
//
//  Created by James Landrum on 9/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import Lottie

class TutorialView : UIView {
    @IBOutlet var view: UIView!
    @IBOutlet weak var lottieHost: UIView!
    @IBOutlet weak var titleText: UILabel!
    @IBOutlet weak var messageText: UILabel!
    
    var lottieView: LOTAnimationView? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        cinit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        cinit()
    }
    
    convenience init(frame: CGRect, title: String, message: String,
                     animation: String) {
        self.init(frame: frame)
        titleText.text = title
        messageText.text = message
        titleText.sizeToFit()
        messageText.sizeToFit()
        
        lottieView = LOTAnimationView(name: animation)
        lottieView!.loopAnimation = true
        lottieHost.addSubview(lottieView!)
        lottieView!.play()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        lottieView?.frame = CGRect(x: 0, y: 0,
                                   width: lottieHost.frame.width,
                                   height: lottieHost.frame.height)
    }
    
    func cinit() {
        Bundle.main.loadNibNamed("TutorialView", owner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
    }
} 
