//
//  GameTipViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/18/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import Combine

class GameTipViewController: UIViewController {
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var reminderButton: UIButton!
    @IBOutlet weak var dividerLine: UIView!
    @IBOutlet weak var favoriteButton: UIButton!
    
    var isFavorited = false
        
    // TODO: Pass in the tip
    static func create() -> GameTipViewController {
        let sb = UIStoryboard(name: "Game", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "TipPopup") as! GameTipViewController
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
        
        detailLabel.textColor = .deepGray
        detailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        reminderButton.tintColor = .actionBlue
        reminderButton.setTitleColor(.actionBlue, for: .normal)
        reminderButton.setTitleColor(UIColor.actionBlue.darker(), for: .highlighted)
        reminderButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        favoriteButton.tintColor = .actionBlue
        favoriteButton.setTitleColor(.actionBlue, for: .normal)
        favoriteButton.setTitleColor(UIColor.actionBlue.darker(), for: .highlighted)
        favoriteButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss(_:)))
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismiss(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onReminderPress() {
        print("set reminder")
    }
    
    @IBAction func onFavoritePress() {
        // TODO: Persist the favorited tip
        
        isFavorited = !isFavorited
        UIView.performWithoutAnimation { // Prevents ugly setTitle animation
            if isFavorited {
                favoriteButton.setImage(#imageLiteral(resourceName: "ic_favetip_remove.pdf"), for: .normal)
                favoriteButton.setTitle(NSLocalizedString("Remove Favorite", comment: ""), for: .normal)
            } else {
                favoriteButton.setImage(#imageLiteral(resourceName: "ic_favetip.pdf"), for: .normal)
                favoriteButton.setTitle(NSLocalizedString("Favorite", comment: ""), for: .normal)
            }
            favoriteButton.layoutIfNeeded()
        }
    }
    

}

extension GameTipViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}
