//
//  PickerView.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

enum PickerView {
    static func showStringPicker(withTitle title: String,
                     data: [String],
                     selectedIndex: Int,
                     onDone: ((_ selectedValue: String, _ selectedIndex: Int) -> ())?,
                     onCancel: (()->())?) {
        
        let picker = StringPickerView(title: title, dataArray: data, onDone: onDone, onCancel: onCancel)
        picker.selectedIndex = selectedIndex
        picker.showInWindow()
    }
    
    static func showTimePicker(withTitle title: String,
                               selectedTime: Date,
                               minTime: Date,
                               maxTime: Date,
                               onDone: ((_ selectedDate: Date) -> ())?,
                               onCancel: (()->())?) {
        
        TimePickerView(title: title,
                       selectedTime: selectedTime,
                       minTime: minTime,
                       maxTime: maxTime,
                       onDone: onDone,
                       onCancel: onCancel)
            .showInWindow()
    }

    static func showDatePicker(withTitle title: String,
                               selectedTime: Date,
                               onDone: ((_ selectedDate: Date) -> ())?,
                               onCancel: (()->())?) {
        
        DatePickerView(title: title,
                       selectedTime: selectedTime,
                       onDone: onDone,
                       onCancel: onCancel)
            .showInWindow()
    }
}

fileprivate class BasePickerView: UIView {
    let mainContainer = UIView().usingAutoLayout()
    let mainStack = UIStackView().usingAutoLayout()
    let cancelButton = UIButton(type: .system).usingAutoLayout()
    let titleLabel = UILabel().usingAutoLayout()
    let doneButton = UIButton(type: .system).usingAutoLayout()
    var hiddenConstraint: NSLayoutConstraint!
    var shownConstraint: NSLayoutConstraint!
    
    var title: String?
    var accessibleElements = [Any]()
    
    private var onCancel: (() -> ())?
    
    init(title: String?, onCancel: (() -> ())?) {
        self.title = title
        self.onCancel = onCancel
        super.init(frame: UIApplication.shared.keyWindow?.bounds ?? .zero)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    func commonInit() {
        backgroundColor = UIColor.black.withAlphaComponent(0)
        
        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.font = SystemFont.semibold.of(size: 18)
        titleLabel.textColor = .deepGray
        titleLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 1), for: .horizontal)
        titleLabel.numberOfLines = 0
        
        cancelButton.setContentHuggingPriority(.required, for: .horizontal)
        cancelButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        cancelButton.titleLabel?.font = SystemFont.regular.of(size: 18)
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        cancelButton.setTitleColor(.actionBlue, for: .normal)
        
        doneButton.setContentHuggingPriority(.required, for: .horizontal)
        doneButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        doneButton.titleLabel?.font = SystemFont.semibold.of(size: 18)
        doneButton.setTitle(NSLocalizedString("Done", comment: ""), for: .normal)
        doneButton.setTitleColor(.actionBlue, for: .normal)
        
        let topBarContainer = UIView().usingAutoLayout()
        topBarContainer.clipsToBounds = true
        topBarContainer.addSubview(doneButton)
        topBarContainer.addSubview(cancelButton)
        topBarContainer.addSubview(titleLabel)
        
        titleLabel.topAnchor.constraint(greaterThanOrEqualTo: topBarContainer.topAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(greaterThanOrEqualTo: topBarContainer.bottomAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cancelButton.trailingAnchor, constant: 8).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: doneButton.leadingAnchor, constant: 8).isActive = true
        let titleLeading = titleLabel.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 8)
        titleLeading.priority = UILayoutPriority(rawValue: 750)
        titleLeading.isActive = true
        let titleTrailing = titleLabel.trailingAnchor.constraint(equalTo: doneButton.leadingAnchor, constant: 8)
        titleTrailing.priority = UILayoutPriority(rawValue: 750)
        titleTrailing.isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: topBarContainer.centerXAnchor).isActive = true
        
        let cancelToTop = cancelButton.topAnchor.constraint(equalTo: topBarContainer.topAnchor)
        cancelToTop.priority = UILayoutPriority(rawValue: 750)
        cancelToTop.isActive = true
        let cancelToBottom = cancelButton.bottomAnchor.constraint(equalTo: topBarContainer.bottomAnchor)
        cancelToBottom.priority = UILayoutPriority(rawValue: 750)
        cancelToBottom.isActive = true
        cancelButton.leadingAnchor.constraint(equalTo: topBarContainer.leadingAnchor, constant: 16).isActive = true
        cancelButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        
        doneButton.trailingAnchor.constraint(equalTo: topBarContainer.trailingAnchor, constant: -16).isActive = true
        doneButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        
        mainStack.addArrangedSubview(topBarContainer)
        mainStack.spacing = 16
        mainStack.axis = .vertical
        
        mainContainer.backgroundColor = .white
        mainContainer.layer.cornerRadius = 13
        mainContainer.addSubview(mainStack)
        mainStack.topAnchor.constraint(equalTo: mainContainer.topAnchor, constant: 8).isActive = true
        mainStack.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor, constant: -22).isActive = true
        mainStack.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor).isActive = true
        mainStack.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor).isActive = true
        
        addSubview(mainContainer)
        mainContainer.addTabletWidthConstraints(horizontalPadding: 8)
        
        shownConstraint = mainContainer.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -13)
        hiddenConstraint = mainContainer.topAnchor.constraint(equalTo: bottomAnchor)
        shownConstraint.isActive = false
        hiddenConstraint.isActive = true
        
        cancelButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneButtonPressed), for: .touchUpInside)
        
        cancelButton.accessibilityLabel = NSLocalizedString("Cancel", comment: "")
        doneButton.accessibilityLabel = NSLocalizedString("Done", comment: "")
        
    }
    
    func showInWindow() {
        guard let window = UIApplication.shared.keyWindow else { return }
        
        window.addSubview(self)
        
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: window.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: window.trailingAnchor).isActive = true
        topAnchor.constraint(equalTo: window.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: window.bottomAnchor).isActive = true
        
        layoutIfNeeded()
        
        show()
    }
    
    @objc private func dismiss() {
        shownConstraint.isActive = false
        hiddenConstraint.isActive = true
        UIView.animate(withDuration: 0.25, animations: {
            self.layoutIfNeeded()
            self.backgroundColor = UIColor.black.withAlphaComponent(0)
        }, completion: { [weak self] _ in
            self?.accessibilityViewIsModal = false
            UIAccessibility.post(notification: .screenChanged, argument: self)
            self?.removeFromSuperview()
        })
    }
    
    func show() {
        hiddenConstraint.isActive = false
        shownConstraint.isActive = true
        UIView.animate(withDuration: 0.25, animations: {
            self.layoutIfNeeded()
            self.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        }, completion: { [weak self] _ in
            self?.accessibilityViewIsModal = true
            UIAccessibility.post(notification: .screenChanged, argument: self)
        })
    }

    @objc func cancelButtonPressed() {
        onCancel?()
        dismiss()
    }

    @objc func doneButtonPressed() {
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

fileprivate class TimePickerView: BasePickerView {
    let datePicker = UIDatePicker()
    let onDone: ((_ selectedDate: Date) -> ())?
    
    init(title: String?,
         selectedTime: Date,
         minTime: Date,
         maxTime: Date,
         onDone: ((_ selectedDate: Date) -> ())?,
         onCancel: (() -> ())?) {
        self.onDone = onDone
        super.init(title: title, onCancel: onCancel)
        datePicker.date = selectedTime
        datePicker.minimumDate = minTime
        datePicker.maximumDate = maxTime
    }
    
    override func commonInit() {
        super.commonInit()
        datePicker.timeZone = .opCo
        datePicker.calendar = .opCo
        datePicker.datePickerMode = .time
        datePicker.minuteInterval = 15
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        mainStack.addArrangedSubview(datePicker)
        accessibleElements = [cancelButton, doneButton, datePicker]
    }
    
    @objc override func doneButtonPressed() {
        onDone?(datePicker.date)
        super.doneButtonPressed()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

fileprivate class StringPickerView: BasePickerView {
    var dataArray = [String]()
    let pickerView = UIPickerView()
    var selectedIndex = 0 {
        didSet {
            pickerView.selectRow(selectedIndex, inComponent: 0, animated: false)
        }
    }
    
    let onDone: ((_ selectedValue: String, _ selectedIndex: Int) -> ())?
    
    init(title: String?,
         dataArray: [String],
         onDone: ((_ selectedValue: String, _ selectedIndex: Int) -> ())?,
         onCancel: (() -> ())?) {
        self.dataArray = dataArray
        self.onDone = onDone
        super.init(title: title, onCancel: onCancel)
    }
    
    override func commonInit() {
        super.commonInit()
        pickerView.dataSource = self
        pickerView.delegate = self
        mainStack.addArrangedSubview(pickerView)
        accessibleElements = [cancelButton, titleLabel, doneButton, pickerView]
    }
    
    @objc override func doneButtonPressed() {
        onDone?(dataArray[selectedIndex], selectedIndex)
        super.doneButtonPressed()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension StringPickerView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dataArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedIndex = row
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension StringPickerView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataArray.count
    }
}



fileprivate class DatePickerView: BasePickerView {
    let datePicker = UIDatePicker()
    let onDone: ((_ selectedDate: Date) -> ())?
    
    init(title: String?,
         selectedTime: Date,
         onDone: ((_ selectedDate: Date) -> ())?,
         onCancel: (() -> ())?) {
        self.onDone = onDone
        super.init(title: title, onCancel: onCancel)
        datePicker.date = selectedTime
    }
    
    override func commonInit() {
        super.commonInit()
        datePicker.timeZone = .opCo
        datePicker.calendar = .opCo
        datePicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        mainStack.addArrangedSubview(datePicker)
        accessibleElements = [cancelButton, doneButton, datePicker]
    }
    
    @objc override func doneButtonPressed() {
        onDone?(datePicker.date)
        super.doneButtonPressed()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}
