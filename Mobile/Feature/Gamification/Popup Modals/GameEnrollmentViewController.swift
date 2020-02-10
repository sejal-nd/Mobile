//
//  GameEnrollmentViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 12/17/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

protocol GameEnrollmentViewControllerDelegate: class {
    func gameEnrollmentViewControllerDidPressCTA(_ gameEnrollmentViewController: GameEnrollmentViewController)
    func gameEnrollmentViewControllerDidPressNotInterested(_ gameEnrollmentViewController: GameEnrollmentViewController)
}

class GameEnrollmentViewController: UIViewController {
    
    weak var delegate: GameEnrollmentViewControllerDelegate?
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var popupView: UIView!
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var ctaButton: PrimaryButton!
    @IBOutlet weak var notInterestedButton: UIButton!
    
    var taskType: GameTaskType! // Passed into create() function
        
    static func create(withTaskType taskType: GameTaskType) -> GameEnrollmentViewController {
        if taskType != .eBill && taskType != .homeProfile {
            fatalError("GameEnrollmentViewController only supports a GameTaskType of .eBill or .homeProfile")
        }
        
        let sb = UIStoryboard(name: "Game", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "EnrollmentPopup") as! GameEnrollmentViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.taskType = taskType
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
        titleLabel.text = NSLocalizedString("Try this out!", comment: "")
        
        detailLabel.textColor = .deepGray
        detailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        var buttonTitle: String
        if taskType == .eBill {
            detailLabel.text = NSLocalizedString("As we work together to reduce your home’s energy usage, enrolling in Paperless eBill is an easy way to make an immediate positive impact on the environment by eliminating your paper bill.\n\nYour online bill is identical to your current paper bill and is available to view, download, or print at any time. You will receive bill ready email notifications regardless of preference. Your preference will be updated with your next month’s bill.", comment: "")
            buttonTitle = NSLocalizedString("Enroll Now", comment: "")
        } else { // Home Profile
            detailLabel.text = NSLocalizedString("Update your home’s profile and get more powerful and personalized insights into your energy use.", comment: "")
            buttonTitle = NSLocalizedString("Update Home Profile", comment: "")
        }
        ctaButton.setTitle(buttonTitle, for: .normal)
        ctaButton.accessibilityLabel = buttonTitle
        
        notInterestedButton.setTitleColor(.actionBlue, for: .normal)
        notInterestedButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss(_:)))
        tap.delegate = self
        contentView.addGestureRecognizer(tap)
    }
    
    @IBAction func onCTAPress() {
        delegate?.gameEnrollmentViewControllerDidPressCTA(self)
    }
    
    @IBAction func onNotInterestedPress() {
        delegate?.gameEnrollmentViewControllerDidPressNotInterested(self)
    }
    
    @objc private func dismiss(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

}

extension GameEnrollmentViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}
