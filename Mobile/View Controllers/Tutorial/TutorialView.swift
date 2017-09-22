//
//  TutorialViewViewController.swift
//  Mobile
//
//  Created by James Landrum on 9/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class TutorialView : UIView {
    @IBOutlet var view: UIView!
    @IBOutlet weak var lottieHost: UIView!
    @IBOutlet weak var titleText: UILabel!
    @IBOutlet weak var messageText: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        cinit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        cinit()
    }
    
    convenience init(frame: CGRect, title: String, message: String,
                     animation: String, imagesRoot: String) {
        self.init(frame: frame)
        titleText.text = title
        messageText.text = message
    }
    
    func cinit() {
        Bundle.main.loadNibNamed("TutorialView", owner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
    }
} 
