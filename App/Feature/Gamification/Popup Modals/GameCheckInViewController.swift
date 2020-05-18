//
//  GameCheckInViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 1/9/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit

protocol GameCheckInViewControllerDelegate: class {
    func gameCheckInViewController(_ gameCheckInViewController: GameCheckInViewController, selectedResponse: String)
    func gameCheckInViewControllerSelectedNotInterested(_ gameCheckInViewController: GameCheckInViewController)
}

class GameCheckInViewController: UIViewController {
    
    weak var delegate: GameCheckInViewControllerDelegate?
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    @IBOutlet weak var button1: SecondaryButton!
    @IBOutlet weak var button2: SecondaryButton!
    @IBOutlet weak var button3: SecondaryButton!
    @IBOutlet weak var notInterestedButton: UIButton!

    static func create() -> GameCheckInViewController {
        let sb = UIStoryboard(name: "Game", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "CheckInPopup") as! GameCheckInViewController
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
        titleLabel.text = NSLocalizedString("Just Checking In!", comment: "")
        
        detailLabel.textColor = .deepGray
        detailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        detailLabel.text = NSLocalizedString("How do you feel about your energy usage?", comment: "")
        
        notInterestedButton.tintColor = .actionBlue
        notInterestedButton.setTitleColor(.actionBlue, for: .normal)
        notInterestedButton.setTitleColor(UIColor.actionBlue.darker(), for: .highlighted)
        notInterestedButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .subheadline)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss(_:)))
        tap.delegate = self
        contentView.addGestureRecognizer(tap)
    }
        
    @objc private func dismiss(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onButtonPress(_ sender: Any) {
        if let selectedAnswerButton = sender as? SecondaryButton, let buttonText = selectedAnswerButton.titleLabel?.text {
            delegate?.gameCheckInViewController(self, selectedResponse: buttonText)
        } else {
            delegate?.gameCheckInViewControllerSelectedNotInterested(self)
        }
        dismiss(self)
    }
    
}

extension GameCheckInViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}
