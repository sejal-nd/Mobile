//
//  DatePickerViewController.swift
//  EUMobile
//
//  Created by Aman Vij on 25/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

protocol DateViewDelegate {
    func getSelectedDate(_ date: Date)
}

class DatePickerViewController: UIViewController {
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var delegate: DateViewDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showDatePicker()
    }
    
    func showDatePicker() {
        datePicker?.date = Date()
        datePicker.datePickerMode = .date
        datePicker?.locale = .current
        datePicker?.preferredDatePickerStyle = .inline
        datePicker?.maximumDate = Date()
    }
    
    @IBAction func datePickerValueChanged(sender: UIDatePicker) {
        self.delegate.getSelectedDate(sender.date)
        self.dismiss(animated: true)
    }
}
