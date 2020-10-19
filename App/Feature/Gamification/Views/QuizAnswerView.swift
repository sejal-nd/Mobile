//
//  QuizAnswerView.swift
//  Mobile
//
//  Created by Marc Shilling on 12/3/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

protocol QuizAnswerViewDelegate: class {
    func quizAnswerViewWasTapped(_ view: QuizAnswerView)
}

class QuizAnswerView: UIView {
    
    weak var delegate: QuizAnswerViewDelegate?

    @IBOutlet weak private var view: UIView!
    @IBOutlet weak var correctIndicatorImageView: UIImageView!
    @IBOutlet weak var answerButton: ButtonControl!
    @IBOutlet weak var answerLabel: UILabel!
    
    var correct = false
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    init(with answer: GameQuiz.Answer) {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 56))
                
        commonInit()
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.hyphenationFactor = 1
        let attribString = NSAttributedString(string: answer.value, attributes: [
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ])
        
        answerLabel.attributedText = attribString
        correct = answer.isCorrect
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("QuizAnswerView", owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        
        correctIndicatorImageView.isHidden = true
        
        answerButton.layer.cornerRadius = 17.5
        answerButton.layer.borderWidth = 1
        answerButton.layer.borderColor = UIColor.accentGray.cgColor
        answerButton.backgroundColorOnPress = .softGray
        
        answerLabel.textColor = .actionBlue
        answerLabel.font = OpenSans.semibold.of(size: 12)
    }
    
    @IBAction func onAnswerPress(_ sender: Any) {
        delegate?.quizAnswerViewWasTapped(self)
    }
    
    func setCorrectState() {
        correctIndicatorImageView.image = correct ? #imageLiteral(resourceName: "ic_trendcheck.pdf") : #imageLiteral(resourceName: "ic_remove.pdf")
        correctIndicatorImageView.isHidden = false
        answerButton.layer.borderWidth = 2
        answerButton.layer.borderColor = correct ? UIColor.successGreenText.cgColor : UIColor.errorRed.cgColor
    }

}
