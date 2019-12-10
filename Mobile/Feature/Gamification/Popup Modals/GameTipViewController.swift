//
//  GameTipViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/18/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class GameTipViewController: UIViewController {
    
    let coreDataManager = GameCoreDataManager()
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var reminderButton: UIButton!
    @IBOutlet weak var dividerLine: UIView!
    @IBOutlet weak var favoriteButton: UIButton!
    
    let accountNumber = AccountsStore.shared.currentAccount.accountNumber
    
    var tip: GameTip! // Passed into create() function
    
    var isReminder = false
    var isFavorite = false
    
    var onUpdate: (() -> Void)?
        
    // TODO: Pass in the tip
    static func create(withTip tip: GameTip) -> GameTipViewController {
        let sb = UIStoryboard(name: "Game", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "TipPopup") as! GameTipViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.tip = tip
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
        contentView.addGestureRecognizer(tap)
        
        populateTipData()
        
        coreDataManager.addViewedTip(accountNumber: accountNumber, tipId: tip.id)
    }
    
    private func populateTipData() {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        var detailText = tip.description
        if let numPeopleStr = numberFormatter.string(for: tip.numPeople) {
            detailText += "\n\nThis worked for \(numPeopleStr) people and can save up to $\(tip.savingsPerYear) per year."
        }
        detailLabel.text = detailText
        
        updateReminderButton()
        
        isFavorite = coreDataManager.isTipFavorited(accountNumber: accountNumber, tipId: tip.id)
        updateFavoriteButton()
    }
    
    @objc private func dismiss(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? LargeTitleNavigationController,
            let vc = navController.viewControllers.first as? SetReminderViewController {
            vc.tip = tip
            vc.onReminderSet = { [weak self] in
                self?.updateReminderButton()
            }
        }
    }
    
    @IBAction func onReminderPress() {
        if isReminder { // Cancel reminder
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [tip.id])
            isReminder = false
            updateReminderButton()
        } else {
            performSegue(withIdentifier: "reminderSegue", sender: nil)
        }
    }
    
    @IBAction func onFavoritePress() {
        isFavorite = !isFavorite
        updateFavoriteButton()
        coreDataManager.updateViewedTip(accountNumber: accountNumber, tipId: tip.id, isFavorite: isFavorite)
        onUpdate?()
    }
    
    private func updateReminderButton() {
        GameTaskStore.shared.fetchTipIdsForPendingReminders() { [weak self] tipIds in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isReminder = tipIds.contains(self.tip.id)
                UIView.performWithoutAnimation { // Prevents ugly setTitle animation
                    if self.isReminder {
                        self.reminderButton.setImage(#imageLiteral(resourceName: "ic_reminder_cancel.pdf"), for: .normal)
                        self.reminderButton.setTitle(NSLocalizedString("Cancel Reminder", comment: ""), for: .normal)
                    } else {
                        self.reminderButton.setImage(#imageLiteral(resourceName: "ic_reminder.pdf"), for: .normal)
                        self.reminderButton.setTitle(NSLocalizedString("Reminder", comment: ""), for: .normal)
                    }
                    self.reminderButton.layoutIfNeeded()
                }
                self.onUpdate?()
            }
        }
    }
    
    private func updateFavoriteButton() {
        UIView.performWithoutAnimation { // Prevents ugly setTitle animation
            if isFavorite {
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
