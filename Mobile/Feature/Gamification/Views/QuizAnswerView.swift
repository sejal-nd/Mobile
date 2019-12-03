//
//  QuizAnswerView.swift
//  Mobile
//
//  Created by Marc Shilling on 12/3/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class QuizAnswerView: UIView {

    @IBOutlet weak private var view: UIView!
    @IBOutlet weak var correctIndicatorImageView: UIImageView!
    @IBOutlet weak var answerButton: ButtonControl!
    @IBOutlet weak var answerLabel: UILabel!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    init(answer: String) {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 56))
                
        commonInit()
        
        answerLabel.text = answer
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("QuizAnswerView", owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        
        correctIndicatorImageView.isHidden = true
        
        answerButton.layer.cornerRadius = 17.5
        answerButton.layer.borderColor = UIColor.accentGray.cgColor
        answerButton.layer.borderWidth = 1
        answerButton.backgroundColorOnPress = UIColor.accentGray
        
        answerLabel.textColor = .actionBlue
        answerLabel.font = OpenSans.semibold.of(size: 12)
    }
}
