//
//  PickerView.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class PickerView: UIView {

    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var exelonPicker: UIPickerView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var dataArray = [String]()
    var accessibleElements = [Any]()
    var selectedIndex = 0
    
    private var onDone: ((_ selectedValue: String, _ selectedIndex: Int) -> ())?
    private var onCancel: (() -> ())?
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    private init(dataArray: [String]) {
        self.dataArray = dataArray
        super.init(frame: UIApplication.shared.keyWindow!.bounds)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
//        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(PickerView.className, owner: self, options: nil)
        
        cancelButton.accessibilityLabel = NSLocalizedString("Cancel", comment: "")
        doneButton.accessibilityLabel = NSLocalizedString("Done", comment: "")
        
        accessibleElements = [cancelButton, doneButton, exelonPicker]
        
        //
        containerView.addSubview(exelonPicker)
        containerView.addSubview(cancelButton)
        containerView.addSubview(doneButton)
        
        addSubview(containerView)
        
        //
        containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
        bottomConstraint = containerView.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                                 constant: containerView.frame.height + 8)
        bottomConstraint.isActive = true
        
        //
        exelonPicker.dataSource = self
        exelonPicker.delegate = self
        exelonPicker.selectRow(0, inComponent: 0, animated: true)
        
        cancelButton.setTitleColor(.actionBlue, for: .normal)
        doneButton.setTitleColor(.actionBlue, for: .normal)
        doneButton.titleLabel?.font = SystemFont.semibold.of(size: 18)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = 8
    }
    
    func selectRow(_ row: Int) {
        selectedIndex = row
        exelonPicker.selectRow(row, inComponent: 0, animated: false)
    }
    
    static func show(withTitle title: String,
                     data: [String],
                     selectedIndex: Int,
                     onDone: ((_ selectedValue: String, _ selectedIndex: Int) -> ())?,
                     onCancel: (()->())?) {
        
        let picker = PickerView(dataArray: data)
        picker.onDone = onDone
        picker.onCancel = onCancel
        picker.selectRow(selectedIndex)
        
        picker.titleLabel.text = title
        
        let window = UIApplication.shared.keyWindow!
        window.addSubview(picker)
        
        picker.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 0).isActive = true
        picker.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: 0).isActive = true
        picker.topAnchor.constraint(equalTo: window.topAnchor, constant: 0).isActive = true
        
        picker.backgroundColor = UIColor.black.withAlphaComponent(0)
        
        picker.layoutIfNeeded()
        
        picker.bottomConstraint.constant = -8
        UIView.animate(withDuration: 0.25, animations: {
            picker.layoutIfNeeded()
            picker.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        }, completion: { [weak picker] _ in
            picker?.accessibilityViewIsModal = false
        })
    }
    
    private func dismiss() {
        bottomConstraint.constant = containerView.frame.height + 8
        UIView.animate(withDuration: 0.25, animations: {
            self.layoutIfNeeded()
            self.backgroundColor = UIColor.black.withAlphaComponent(0)
        }, completion: { [weak self] _ in
            self?.accessibilityViewIsModal = true
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self)
            self?.removeFromSuperview()
        })
    }

    @IBAction func cancelButtonPressed(_ sender: Any) {
        onCancel?()
        dismiss()
    }

    @IBAction func doneButtonPressed(_ sender: Any) {
        onDone?(dataArray[selectedIndex], selectedIndex)
        dismiss()
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
extension PickerView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dataArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedIndex = row
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension PickerView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataArray.count
    }
}


