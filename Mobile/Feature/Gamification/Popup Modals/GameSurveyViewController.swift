//
//  GameSurveyViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 12/26/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

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
    
    private let surveyManager = SurveyMonkeyManager()
    
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
        
        closeButton.tintColor = .actionBlue
        closeButton.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
        
        titleLabel.textColor = .deepGray
        titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        titleLabel.text = NSLocalizedString("We'd love your feedback!", comment: "")
        
        detailLabel.textColor = .deepGray
        detailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        let detailText = survey.surveyNumber == 1 ?
            NSLocalizedString("We appreciate your time, so we’ll keep it short!", comment: "") :
            NSLocalizedString("Thank you for participating in the experience! Now that it’s been a while, we’d love to hear more from you.", comment: "")
        detailLabel.text = detailText
        
        let takeSurveyButtonTitle = survey.surveyNumber == 1 ?
            NSLocalizedString("Take Survey", comment: "") :
            NSLocalizedString("Take Survey #2", comment: "")
        UIView.performWithoutAnimation { // Prevents ugly setTitle animation
            takeSurveyButton.setTitle(takeSurveyButtonTitle, for: .normal)
            takeSurveyButton.layoutIfNeeded()
        }
        
        remindMeLaterButton.tintColor = .actionBlue
        remindMeLaterButton.setTitleColor(.actionBlue, for: .normal)
        remindMeLaterButton.setTitleColor(UIColor.actionBlue.darker(), for: .highlighted)
        remindMeLaterButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        if survey.attempt == 3 {
            dividerLine.isHidden = true
            remindMeLaterButton.isHidden = true
        }
        
        notInterestedButton.tintColor = .actionBlue
        notInterestedButton.setTitleColor(.actionBlue, for: .normal)
        notInterestedButton.setTitleColor(UIColor.actionBlue.darker(), for: .highlighted)
        notInterestedButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
                
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss(_:)))
        tap.delegate = self
        contentView.addGestureRecognizer(tap)
    }
        
    @objc private func dismiss(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
        
    @IBAction func onTakeSurveyPress() {
        let surveyHash = survey.surveyNumber == 1 ? "NYLFJP3" : "NYLFJP3" // TODO: Final survey hashes
        surveyManager.presentSurvey(withHash: surveyHash, from: self) { [weak self] in
            guard let self = self else { return }
            self.setSurveyComplete()
            self.presentingViewController?.dismiss(animated: true, completion: {
                self.delegate?.gameSurveyViewControllerDidFinish(self, surveyComplete: true)
            })
        }
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

