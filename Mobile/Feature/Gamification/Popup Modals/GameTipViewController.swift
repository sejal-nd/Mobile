//
//  GameTipViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/18/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

protocol GameTipViewControllerDelegate: class {
    func gameTipViewControllerWasDismissed(_ gameTipViewController: GameTipViewController, withQuizPoints quizPoints: Double)
}

class GameTipViewController: UIViewController {
    
    weak var delegate: GameTipViewControllerDelegate?
    
    let coreDataManager = GameCoreDataManager()
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var reminderButton: UIButton!
    @IBOutlet weak var dividerLine: UIView!
    @IBOutlet weak var favoriteButton: UIButton!
    
    private let datePicker = UIDatePicker()
    
    let accountNumber = AccountsStore.shared.currentAccount.accountNumber
    
    // Passed into create() function
    var tip: GameTip!
    var quizPoints: Double!
    
    var isReminder = false
    var isFavorite = false
    
    var onUpdate: (() -> Void)?
        
    static func create(withTip tip: GameTip, quizPoints: Double = 0) -> GameTipViewController {
        let sb = UIStoryboard(name: "Game", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "TipPopup") as! GameTipViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.tip = tip
        vc.quizPoints = quizPoints
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
        titleLabel.text = NSLocalizedString("I have a tip for you!", comment: "")
        
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
        
        let hourFromNow = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date.now)!
        
        datePicker.datePickerMode = .dateAndTime
        datePicker.date = tomorrow
        datePicker.minimumDate = hourFromNow
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss(_:)))
        tap.delegate = self
        contentView.addGestureRecognizer(tap)
        
        populateTipData()
        
        coreDataManager.addViewedTip(accountNumber: accountNumber, tipId: tip.id)
    }
    
    private func populateTipData() {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        var detailText = tip.title + "\n\n" + tip.description
        if let numPeople = tip.numPeople, let numPeopleStr = numberFormatter.string(for: numPeople), let savings = tip.savingsPerYear {
            detailText += "\n\nThis worked for \(numPeopleStr) people and can save up to $\(savings) per year."
        } else if let numPeople = tip.numPeople, let numPeopleStr = numberFormatter.string(for: numPeople) {
            detailText += "\n\nThis worked for \(numPeopleStr) people."
        } else if let savings = tip.savingsPerYear {
            detailText += "\n\nThis can save up to $\(savings) per year."
        }
        detailLabel.text = detailText
        
        updateReminderButton()
        
        isFavorite = coreDataManager.isTipFavorited(accountNumber: accountNumber, tipId: tip.id)
        updateFavoriteButton()
    }
    
    @objc private func dismiss(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: {
            self.delegate?.gameTipViewControllerWasDismissed(self, withQuizPoints: self.quizPoints)
        })
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
            //performSegue(withIdentifier: "reminderSegue", sender: nil)
            
            let dateAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            dateAlert.view.addSubview(datePicker)
            dateAlert.view.heightAnchor.constraint(equalToConstant: 336).isActive = true
            
            let setReminderAction = UIAlertAction(title: "Set Reminder", style: .default, handler: { [weak self] action in
                guard let self = self else { return }
                
                let content = UNMutableNotificationContent()
                content.title = "Your Energy Buddy Has a Reminder for You!"
                content.body = self.tip.title
                content.sound = .default
                
                let dateComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self.datePicker.date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComps, repeats: false)
                
                let request = UNNotificationRequest(identifier: self.tip.id, content: content, trigger: trigger)
        
                UNUserNotificationCenter.current().add(request, withCompletionHandler: { [weak self] error in
                    DispatchQueue.main.async {
                        if error != nil {
                            let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                                            message: NSLocalizedString("Could not set reminder. Try again.", comment: ""),
                                                            preferredStyle: .alert)
                            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                            self?.present(alertVc, animated: true, completion: nil)
                        } else {
                            self?.updateReminderButton()
                        }
                    }
                })
            })
            dateAlert.addAction(setReminderAction)
            dateAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(dateAlert, animated: true, completion: nil)
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
