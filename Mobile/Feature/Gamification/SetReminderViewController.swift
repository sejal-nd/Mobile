//
//  SetReminderViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 12/10/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

/*
 *
 *  NOTE: This ViewController is not used in the initial pilot version. We've opted instead to simply
 *  display the date picker popup directly from the tip. Keeping the file around in case we ever want
 *  to go back to the standalone Set Reminder screen.
 *
 */

import RxSwift
import RxCocoa

class SetReminderViewController: KeyboardAvoidingStickyFooterViewController {

    @IBOutlet weak var reminderNameTextField: FloatLabelTextField!
    @IBOutlet weak var dateButton: DisclosureButton!
    @IBOutlet weak var saveButton: PrimaryButton!
    
    private let datePicker = UIDatePicker()
    private let reminderName = BehaviorRelay<String>(value: "")
    
    private let bag = DisposeBag()
    
    // Passed by GameTipViewController
    var tip: GameTip!
    var onReminderSet: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addCloseButton()

        reminderNameTextField.setEnabled(false)
        reminderNameTextField.placeholder = NSLocalizedString("Reminder Name", comment: "")
        reminderNameTextField.textField.text = tip.title
        reminderNameTextField.textField.rx.text.orEmpty.bind(to: reminderName).disposed(by: bag)
        reminderName.asDriver().map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }.drive(saveButton.rx.isEnabled).disposed(by: bag)
        
        let now = Date.now
        
        dateButton.valueText = now.gameReminderString
        
        datePicker.datePickerMode = .dateAndTime
        datePicker.date = now
        datePicker.minimumDate = now
        datePicker.maximumDate = Calendar.current.date(byAdding: .year, value: 2, to: now)
        datePicker.addTarget(self, action: #selector(onDateChange), for: .valueChanged)
    }
    
    @objc func onDateChange() {
        dateButton.valueText = datePicker.date.gameReminderString
    }
    
    @IBAction func onDateButtonPress(_ sender: Any) {
        let dateAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        dateAlert.view.addSubview(datePicker)
        dateAlert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: nil))
        dateAlert.view.heightAnchor.constraint(equalToConstant: 276).isActive = true
        self.present(dateAlert, animated: true, completion: nil)
    }
    
    @IBAction func onSavePress() {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = "I have a reminder for you: \(reminderName.value)"
        content.sound = .default
        
        let dateComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: datePicker.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComps, repeats: false)
        
        let request = UNNotificationRequest(identifier: tip.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { [weak self] error in
            DispatchQueue.main.async {
                if error != nil {
                    let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                                    message: NSLocalizedString("Could not set reminder. Try again.", comment: ""),
                                                    preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self?.present(alertVc, animated: true, completion: nil)
                } else {
                    self?.onReminderSet?()
                    self?.dismiss(animated: true, completion: nil)
                }
            }
        })
    }
}
