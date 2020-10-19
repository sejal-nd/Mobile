//
//  GameQuizViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 12/3/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

protocol GameQuizViewControllerDelegate: class {
    /// Only fired if the user selects a quiz answer first
    func gameQuizViewController(_ viewController: GameQuizViewController, wasDismissedWithCorrectAnswer correct: Bool)
    func gameQuizViewController(_ viewController: GameQuizViewController, wantsToViewTipWithId tipId: String, withCorrectAnswer correct: Bool)
}

class GameQuizViewController: UIViewController {
    
    weak var delegate: GameQuizViewControllerDelegate?
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerStackView: UIStackView!
    @IBOutlet weak var answerDescriptionLabel: UILabel!
    @IBOutlet weak var viewTipButton: PrimaryButton!
    
    private var answerViews = [QuizAnswerView]()
    
    var quiz: GameQuiz! // Passed into create() function
    
    var selectedAnswerView: QuizAnswerView?
    
    static func create(withQuiz quiz: GameQuiz) -> GameQuizViewController {
        let sb = UIStoryboard(name: "Game", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "QuizPopup") as! GameQuizViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.quiz = quiz
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    
        popupView.layer.cornerRadius = 10
        popupView.layer.masksToBounds = true
        
        closeButton.tintColor = .actionBlue
        closeButton.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
        
        titleLabel.textColor = .deepGray
        titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        questionLabel.textColor = .deepGray
        questionLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        answerDescriptionLabel.textColor = .deepGray
        answerDescriptionLabel.font = SystemFont.regular.of(textStyle: .footnote)
        answerDescriptionLabel.isHidden = true
        
        viewTipButton.isHidden = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss(_:)))
        tap.delegate = self
        contentView.addGestureRecognizer(tap)
        
        // Populate quiz data
        questionLabel.text = quiz.question
        for answer in quiz.answers {
            let answerView = QuizAnswerView(with: answer)
            answerView.delegate = self
            answerViews.append(answerView)
            answerStackView.addArrangedSubview(answerView)
        }
        answerDescriptionLabel.text = quiz.answerDescription
    }
    
    @IBAction func onViewTipPress() {
        // Force unwrap safe because View Tip button only visible when not nil
        delegate?.gameQuizViewController(self, wantsToViewTipWithId: quiz.tipId!, withCorrectAnswer: selectedAnswerView!.correct)
    }
        
    @objc private func dismiss(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: {
            if let selectedAnswerView = self.selectedAnswerView {
                self.delegate?.gameQuizViewController(self, wasDismissedWithCorrectAnswer: selectedAnswerView.correct)
            }
        })
    }
    
}

extension GameQuizViewController: QuizAnswerViewDelegate {
    func quizAnswerViewWasTapped(_ view: QuizAnswerView) {
        guard selectedAnswerView == nil else { return } // Prevent double selection

        selectedAnswerView = view
        
        answerStackView.isUserInteractionEnabled = false
        
        view.setCorrectState() // Check or X on the tapped view

        let generator = UINotificationFeedbackGenerator()
        if view.correct {
            generator.notificationOccurred(.success)
        } else {
            generator.notificationOccurred(.error)
            for answerView in answerViews { // If answered incorrectly, find the correct view and show the check
                if answerView.correct {
                    answerView.setCorrectState()
                }
            }
        }
        
        answerDescriptionLabel.isHidden = false
        viewTipButton.isHidden = quiz.tipId == nil
    }
}

extension GameQuizViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}
