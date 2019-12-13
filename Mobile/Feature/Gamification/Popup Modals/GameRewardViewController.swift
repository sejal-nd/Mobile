//
//  GameRewardViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 12/5/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class GameRewardViewController: UIViewController {
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var popupView: UIView!
    
    @IBOutlet weak var fadeView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var button: PrimaryButton!
    
    var rewardRevealed = false
    var animating = false
    
    var setItemCallback: (() -> Void)? // Should be set by presenter
    var gift: Gift! // Passed into create() function
        
    static func create(withGift gift: Gift) -> GameRewardViewController {
        let sb = UIStoryboard(name: "Game", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "RewardPopup") as! GameRewardViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.gift = gift
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    
        popupView.layer.cornerRadius = 10
        popupView.layer.masksToBounds = true
        
        closeButton.tintColor = .actionBlue
        closeButton.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
        closeButton.isHidden = true
        
        titleLabel.textColor = .deepGray
        titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        titleLabel.text = NSLocalizedString("Here’s a gift for your hard work!", comment: "")
    }
    
    @IBAction func onButtonPress() {
        if animating { return }
        
        if rewardRevealed {
            switch gift.type {
            case .background:
                UserDefaults.standard.set(gift.id, forKey: UserDefaultKeys.gameSelectedBackground)
            case .hat:
                UserDefaults.standard.set(gift.id, forKey: UserDefaultKeys.gameSelectedHat)
            case .accessory:
                UserDefaults.standard.set(gift.id, forKey: UserDefaultKeys.gameSelectedAccessory)
            }
            if let callback = setItemCallback {
                callback()
            }
        } else { // Transition to the revealed state
            animating = true
            UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
                self.fadeView.alpha = 0
            }, completion: { _ in
                self.closeButton.isHidden = false
                self.imageView.image = self.gift.thumbImage
                
                let giftTypeString = self.gift.type.rawValue as String
                self.titleLabel.text = String.localizedStringWithFormat("You received a new %@ for your Energy Buddy!", giftTypeString)
                UIView.performWithoutAnimation { // Prevents ugly setTitle animation
                    self.button.setTitle(NSLocalizedString("Set as \(giftTypeString.capitalized)", comment: ""), for: .normal)
                    self.button.layoutIfNeeded()
                }
                
                self.view.layoutIfNeeded()
                UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
                    self.fadeView.alpha = 1
                    self.titleLabelTopConstraint.constant = 51
                    self.view.layoutIfNeeded()
                }, completion: { _ in
                    self.animating = false
                    self.rewardRevealed = true
                    
                    // Enable tap outside to dismiss
                    let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismiss(_:)))
                    tap.delegate = self
                    self.contentView.addGestureRecognizer(tap)
                })
            })
        }
    }
        
    @objc private func dismiss(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

}

extension GameRewardViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}
