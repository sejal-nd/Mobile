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
    var accessibleElements: [Any]
    var selectedIndex = 0

    override init(frame: CGRect) {
        dataArray = []
        accessibleElements = []
        super.init(frame: frame)
        
        commonInit()
    }
    
    init(frame: CGRect, dataArray: [String]) {
        self.dataArray = dataArray
        accessibleElements = []
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        dataArray = []
        accessibleElements = []
        super.init(coder: aDecoder)
        
//        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(ExelonPickerContainerView.className, owner: self, options: nil)
        
        cancelButton.isAccessibilityElement = true
        cancelButton.accessibilityLabel = NSLocalizedString("Cancel", comment: "")
        
        doneButton.isAccessibilityElement = true
        doneButton.accessibilityLabel = NSLocalizedString("Done", comment: "")
        
        accessibleElements = [cancelButton, doneButton, exelonPicker]
        
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
        
        exelonPicker.isAccessibilityElement = true
        exelonPicker.accessibilityLabel = NSLocalizedString("Select premise", comment: "")
        
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
    
    //MARK: UIA11yContainer functions
    
    override var isAccessibilityElement: Bool {
        get {
            return false
        }
        
        set {
            super.isAccessibilityElement = newValue
        }
    }
    
    override var accessibilityElements: [Any]? {
        get {
            return accessibleElements
        }
        set {
            super.accessibilityElements = newValue
        }
    }
    
    override func accessibilityElementCount() -> Int {
        return accessibleElements.count
    }
    
    override func accessibilityElement(at index: Int) -> Any? {
        return accessibleElements[index]
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



