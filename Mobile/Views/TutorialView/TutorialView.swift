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
    
    var lottieView: LOTAnimationView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    convenience init(frame: CGRect, title: String, message: String,
                     animation: String) {
        self.init(frame: frame)
        titleText.text = title
        messageText.text = message
        
        lottieView = LOTAnimationView(name: animation)
        lottieView?.contentMode = .scaleAspectFit
        lottieView?.frame = CGRect(x: 0, y: 0, width: lottieHost.frame.width, height: lottieHost.frame.height)
        lottieView?.translatesAutoresizingMaskIntoConstraints = true
        lottieView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        lottieView!.loopAnimation = true
        lottieHost.addSubview(lottieView!)
        lottieView!.play()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("TutorialView", owner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
        
        titleText.font = OpenSans.regular.of(textStyle: .body)
        messageText.font = SystemFont.regular.of(textStyle: .footnote)
    }
} 
