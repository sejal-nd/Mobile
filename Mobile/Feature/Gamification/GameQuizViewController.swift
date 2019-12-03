//
//  GameQuizViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 12/3/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class GameQuizViewController: UIViewController {
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    
    @IBOutlet weak var answerDescriptionLabel: UILabel!
    @IBOutlet weak var viewTipButton: PrimaryButton!
            
    // TODO: Pass in the quiz
    static func create() -> GameQuizViewController {
        let sb = UIStoryboard(name: "Game", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "QuizPopup") as! GameQuizViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    
        popupView.layer.cornerRadius = 10
        popupView.layer.masksToBounds = false
        
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
    }
        
    @objc private func dismiss(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

extension GameQuizViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}
