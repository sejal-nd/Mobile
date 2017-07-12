//
//  ExelonPickerContainerView.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

protocol ExelonPickerDelegate {
    func donePressed(selectedIndex: Int)
    
    func cancelPressed()
}

class ExelonPickerContainerView: UIView {
    
    var delegate: ExelonPickerDelegate?

    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var exelonPicker: UIPickerView!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var dataArray: [String]
    var selectedIndex = 0

    override init(frame: CGRect) {
        dataArray = []
        super.init(frame: frame)
        
        commonInit()
    }
    
    init(frame: CGRect, dataArray: [String]) {
        self.dataArray = dataArray
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        dataArray = []
        super.init(coder: aDecoder)
        
//        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(ExelonPickerContainerView.className, owner: self, options: nil)
        
        //
        containerView.addSubview(exelonPicker)
        containerView.addSubview(cancelButton)
        containerView.addSubview(doneButton)
        
        addSubview(containerView)
        
        //
        containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8).isActive = true
        containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8).isActive = true
        bottomConstraint = containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8)
        bottomConstraint.isActive = true
        
        //
        exelonPicker.dataSource = self
        exelonPicker.delegate = self
        exelonPicker.selectRow(0, inComponent: 0, animated: true)
    }
    
    func addNewData(dataArray: [String]) {
        self.dataArray = dataArray
        exelonPicker.reloadAllComponents()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.layer.cornerRadius = 8
    }
    
    func selectRow(_ row: Int) {
        selectedIndex = row
        exelonPicker.selectRow(row, inComponent: 0, animated: false)
    }

    @IBAction func cancelButtonPressed(_ sender: Any) {
        delegate?.cancelPressed()
    }

    @IBAction func doneButtonPressed(_ sender: Any) {
        delegate?.donePressed(selectedIndex: selectedIndex)
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension ExelonPickerContainerView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.dataArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedIndex = row
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension ExelonPickerContainerView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataArray.count
    }
}



