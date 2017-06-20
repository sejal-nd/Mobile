//
//  BGEAutoPaySettingsViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//


class BGEAutoPaySettingsViewController: UIViewController {
    
    var selectedUntilDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("AutoPay Settings", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = submitButton
    }
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    func onSubmitPress() {
        print("Submit")
    }
    
    @IBAction func onCalendarPress() {
        let calendarVC = PDTSimpleCalendarViewController()
        calendarVC.delegate = self
        calendarVC.title = NSLocalizedString("Select Date", comment: "")
        calendarVC.lastDate = Calendar.current.date(byAdding: .year, value: 100, to: Date())
        navigationController?.pushViewController(calendarVC, animated: true)
    }

}

extension BGEAutoPaySettingsViewController: PDTSimpleCalendarViewDelegate {
    
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, isEnabledDate date: Date!) -> Bool {
        return date >= Calendar.current.startOfDay(for: Date())
    }
    
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        print("Selected date ", date)
        selectedUntilDate = date
    }
    
}
