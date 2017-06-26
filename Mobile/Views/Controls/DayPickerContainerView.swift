//
//  DayPickerContainerView.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

protocol DayPickerDelegate {
    func donePressed(selectedDay: Int)
    
    func cancelPressed()
}

class DayPickerContainerView: UIView {
    
    var delegate: DayPickerDelegate!

    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var dayPicker: UIPickerView!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var selectedDay = 1

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
//        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(DayPickerContainerView.className, owner: self, options: nil)
        
        //
        containerView.addSubview(dayPicker)
        containerView.addSubview(cancelButton)
        containerView.addSubview(doneButton)
        
        addSubview(containerView)
        
        //
        containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8).isActive = true
        containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8).isActive = true
        bottomConstraint = containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8)
        bottomConstraint.isActive = true
        
        //
        dayPicker.dataSource = self
        dayPicker.delegate = self
        dayPicker.selectRow(0, inComponent: 0, animated: true)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.layer.cornerRadius = 8
    }
    
    func selectRow(_ row: Int) {
        dayPicker.selectRow(row, inComponent: 0, animated: true)
    }

    @IBAction func cancelButtonPressed(_ sender: Any) {
        delegate.cancelPressed()
    }

    @IBAction func doneButtonPressed(_ sender: Any) {
        delegate.donePressed(selectedDay: selectedDay)
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension DayPickerContainerView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let plural = row > 0 ? "s" : ""
        
        return "\(row + 1) Day\(plural)" //self.dataArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedDay = row + 1
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension DayPickerContainerView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 15
    }
}



