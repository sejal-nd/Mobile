//
//  GameSurveyViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 12/26/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import ForeSee
import ForeSeeFeedback

protocol GameSurveyViewControllerDelegate: class {
    func gameSurveyViewControllerDidFinish(_ viewController: GameSurveyViewController, surveyComplete: Bool)
}

class GameSurveyViewController: UIViewController {
    
    weak var delegate: GameSurveyViewControllerDelegate?

    let coreDataManager = GameCoreDataManager()
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var takeSurveyButton: PrimaryButton!
    @IBOutlet weak var remindMeLaterButton: UIButton!
    @IBOutlet weak var dividerLine: UIView!
    @IBOutlet weak var notInterestedButton: UIButton!

    let accountNumber = AccountsStore.shared.currentAccount.accountNumber
        
    var survey: GameSurvey! // Passed into create()
            
    static func create(withSurvey survey: GameSurvey) -> GameSurveyViewController {
        let sb = UIStoryboard(name: "Game", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SurveyPopup") as! GameSurveyViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.survey = survey
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    
        popupView.layer.cornerRadius = 10
        popupView.layer.masksToBounds = true
        
        closeButton.tintColor = .actionBrand
        closeButton.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
        
        titleLabel.textColor = .neutralDark
        titleLabel.font = .headline
        titleLabel.text = NSLocalizedString("We'd love your feedback!", comment: "")
        
        detailLabel.textColor = .neutralDark
        detailLabel.font = .footnote
        detailLabel.text = NSLocalizedString("Thank you for participating in BGE's Play-n-Save pilot program. What do you think of the new energy saving features added to our mobile app? Take this quick survey and let us know!", comment: "")
        
        let takeSurveyButtonTitle = survey.surveyNumber == 1 ?
            NSLocalizedString("Take Survey", comment: "") :
            NSLocalizedString("Take Survey #2", comment: "")
        UIView.performWithoutAnimation { // Prevents ugly setTitle animation
            takeSurveyButton.setTitle(takeSurveyButtonTitle, for: .normal)
            takeSurveyButton.layoutIfNeeded()
        }
        
        remindMeLaterButton.tintColor = .actionBrand
        remindMeLaterButton.setTitleColor(.actionBrand, for: .normal)
        remindMeLaterButton.setTitleColor(UIColor.primaryBlue.darker(), for: .highlighted)
        remindMeLaterButton.titleLabel?.font = .headlineSemibold
        if survey.attempt == 3 {
            dividerLine.isHidden = true
            remindMeLaterButton.isHidden = true
        }
        
        notInterestedButton.tintColor = .actionBrand
        notInterestedButton.setTitleColor(.actionBrand, for: .normal)
        notInterestedButton.setTitleColor(UIColor.primaryBlue.darker(), for: .highlighted)
        notInterestedButton.titleLabel?.font = .headlineSemibold
                
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss(_:)))
        tap.delegate = self
        contentView.addGestureRecognizer(tap)
        
        ForeSeeFeedbackComponent.setFeedbackListener(delegate: self)
    }
        
    @objc private func dismiss(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
        
    @IBAction func onTakeSurveyPress() {
        ForeSee.resetState()
        
        let surveyName = survey.surveyNumber == 1 ? "Survey 1" : "Survey 2"
        ForeSeeFeedbackComponent.showFeedbackForName(surveyName)
    }
        
    @IBAction func onRemindMeLaterPress() {
        presentingViewController?.dismiss(animated: true, completion: {
            self.delegate?.gameSurveyViewControllerDidFinish(self, surveyComplete: false)
        })
    }
    
    @IBAction func onNotInterestedPress() {
        setSurveyComplete()
        presentingViewController?.dismiss(animated: true, completion: {
            self.delegate?.gameSurveyViewControllerDidFinish(self, surveyComplete: false)
        })
    }
    
    private func setSurveyComplete() {
        if survey.surveyNumber == 1 {
            UserDefaults.standard.set(true, forKey: UserDefaultKeys.gameSurvey1Complete)
        } else {
            UserDefaults.standard.set(true, forKey: UserDefaultKeys.gameSurvey2Complete)
        }
    }
        
}

extension GameSurveyViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}

extension GameSurveyViewController: ForeSeeFeedbackDelegate {
    func feedbackSubmitted(_ feedbackName: String) {
        self.setSurveyComplete()
        self.presentingViewController?.dismiss(animated: true, completion: {
            self.delegate?.gameSurveyViewControllerDidFinish(self, surveyComplete: true)
        })
    }
}
