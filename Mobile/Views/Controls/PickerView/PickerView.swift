//
//  PickerView.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

enum PickerView {
    static func show(withTitle title: String,
                     data: [String],
                     selectedIndex: Int,
                     onDone: ((_ selectedValue: String, _ selectedIndex: Int) -> ())?,
                     onCancel: (()->())?) {
        let picker = StringPickerView(title: title, dataArray: data, onDone: onDone, onCancel: onCancel)
        picker.selectedIndex = selectedIndex
        
        guard let window = UIApplication.shared.keyWindow else { return }
        
        window.addSubview(picker)
        
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.leadingAnchor.constraint(equalTo: window.leadingAnchor).isActive = true
        picker.trailingAnchor.constraint(equalTo: window.trailingAnchor).isActive = true
        picker.topAnchor.constraint(equalTo: window.topAnchor).isActive = true
        picker.bottomAnchor.constraint(equalTo: window.bottomAnchor).isActive = true
        
        picker.layoutIfNeeded()
        
        picker.show()
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
    
    func commonInit() {
        backgroundColor = UIColor.black.withAlphaComponent(0)
        
        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.font = SystemFont.semibold.of(size: 18)
        titleLabel.textColor = .deepGray
        titleLabel.setContentHuggingPriority(1, for: .horizontal)
        titleLabel.numberOfLines = 0
        
        cancelButton.setContentHuggingPriority(1000, for: .horizontal)
        cancelButton.titleLabel?.font = SystemFont.regular.of(size: 18)
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        cancelButton.setTitleColor(.actionBlue, for: .normal)
        
        doneButton.setContentHuggingPriority(1000, for: .horizontal)
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
        titleLabel.centerXAnchor.constraint(equalTo: topBarContainer.centerXAnchor).isActive = true
        
        let cancelToTop = cancelButton.topAnchor.constraint(equalTo: topBarContainer.topAnchor)
        cancelToTop.priority = 750
        cancelToTop.isActive = true
        let cancelToBottom = cancelButton.bottomAnchor.constraint(equalTo: topBarContainer.bottomAnchor)
        cancelToBottom.priority = 750
        cancelToBottom.isActive = true
        cancelButton.leadingAnchor.constraint(equalTo: topBarContainer.leadingAnchor, constant: 16).isActive = true
        cancelButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        
        doneButton.trailingAnchor.constraint(equalTo: topBarContainer.trailingAnchor, constant: -16).isActive = true
        doneButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        
        mainStack.addArrangedSubview(topBarContainer)
        mainStack.spacing = 16
        mainStack.axis = .vertical
        
        mainContainer.backgroundColor = .white
        mainContainer.layer.cornerRadius = 8
        mainContainer.addSubview(mainStack)
        mainStack.topAnchor.constraint(equalTo: mainContainer.topAnchor, constant: 8).isActive = true
        mainStack.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor, constant: -22).isActive = true
        mainStack.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor).isActive = true
        mainStack.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor).isActive = true
        
        addSubview(mainContainer)
        
        // Tablet Constraints
        mainContainer.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8).isActive = true
        let leading = mainContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        leading.priority = 750
        leading.isActive = true
        
        mainContainer.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8).isActive = true
        let trailing = mainContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        trailing.priority = 750
        trailing.isActive = true
        
        mainContainer.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: 460).isActive = true
        let width = mainContainer.widthAnchor.constraint(equalToConstant: 460)
        width.priority = 750
        width.isActive = true
        
        mainContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        shownConstraint = mainContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -13)
        shownConstraint.isActive = false
        hiddenConstraint = mainContainer.topAnchor.constraint(equalTo: bottomAnchor)
        hiddenConstraint.isActive = true
        
        cancelButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneButtonPressed), for: .touchUpInside)
        
        cancelButton.accessibilityLabel = NSLocalizedString("Cancel", comment: "")
        doneButton.accessibilityLabel = NSLocalizedString("Done", comment: "")
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    
    
    @objc private func dismiss() {
        shownConstraint.isActive = false
        hiddenConstraint.isActive = true
        UIView.animate(withDuration: 0.25, animations: {
            self.layoutIfNeeded()
            self.backgroundColor = UIColor.black.withAlphaComponent(0)
        }, completion: { [weak self] _ in
            self?.accessibilityViewIsModal = true
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self)
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
            self?.accessibilityViewIsModal = false
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


fileprivate class StringPickerView: BasePickerView {
    var dataArray = [String]()
    let pickerView = UIPickerView()
    var selectedIndex = 0 {
        didSet {
            pickerView.selectRow(selectedIndex, inComponent: 0, animated: false)
        }
    }
    
    private var onDone: ((_ selectedValue: String, _ selectedIndex: Int) -> ())?
    
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
        accessibleElements = [cancelButton, doneButton, pickerView]
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


