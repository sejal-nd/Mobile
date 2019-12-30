//
//  GameSurveyViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 12/26/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class GameSurveyViewController: UIViewController {

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
            
    static func create() -> GameSurveyViewController {
        let sb = UIStoryboard(name: "Game", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SurveyPopup") as! GameSurveyViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
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
        detailLabel.text = NSLocalizedString("We appreciate your time, so we’ll keep it short!", comment: "")
        
        remindMeLaterButton.tintColor = .actionBlue
        remindMeLaterButton.setTitleColor(.actionBlue, for: .normal)
        remindMeLaterButton.setTitleColor(UIColor.actionBlue.darker(), for: .highlighted)
        remindMeLaterButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        
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
        surveyManager.presentSurvey(withHash: "NYLFJP3", from: self) {
            print("survey completion")
        }
    }
        
    @IBAction func onRemindMeLaterPress() {

    }
    
    @IBAction func onNotInterestedPress() {
        
    }
        
}

extension GameSurveyViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}

