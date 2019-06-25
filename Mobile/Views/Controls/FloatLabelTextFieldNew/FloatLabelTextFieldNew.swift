//
//  FloatLabelTextFieldNew.swift
//  Mobile
//
//  Created by Marc Shilling on 6/24/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import JVFloatLabeledTextField
import RxSwift
import RxCocoa

class FloatLabelTextFieldNew: UIView {
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var textFieldContainerView: UIView!
    @IBOutlet weak var textField: InsetTextField!
    @IBOutlet weak var checkAccessoryImageView: UIImageView!
    
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    
    var errorState = false
    var textFieldIsFocused = false
    var errorMessage = ""
    
    let disposeBag = DisposeBag()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        self.backgroundColor = .clear
        
        Bundle.main.loadNibNamed(className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
        
        errorLabel.textColor = .errorRed
        errorLabel.font = SystemFont.regular.of(textStyle: .footnote)
        errorLabel.text = nil
        errorView.isHidden = true
        
        textField.font = SystemFont.regular.of(textStyle: .title1)
//        textField.floatingLabelFont = SystemFont.semibold.of(textStyle: .caption1)
//        textField.floatingLabelYPadding = 6
//        textField.floatingLabelTextColor = .middleGray
//        textField.floatingLabelActiveTextColor = .primaryColorDark
        
        textField.rx.controlEvent(.editingDidBegin).asObservable().subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            if !self.errorState {
                self.textFieldContainerView.layer.borderColor = UIColor.primaryColor.cgColor
            }
            self.textFieldIsFocused = true
        }).disposed(by: disposeBag)
        
        textField.rx.controlEvent(.editingDidEnd).asObservable().subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            if !self.errorState {
                self.textFieldContainerView.layer.borderColor = UIColor.accentGray.cgColor
            }
            self.textFieldIsFocused = false
        }).disposed(by: disposeBag)
        
        textFieldContainerView.fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)
        
        setDefaultStyles()
    }
    
    func setDefaultStyles() {
        textFieldContainerView.backgroundColor = .white
        
//        textField.placeholderColor = .middleGray
//        textField.setPlaceholder(textField.placeholder, floatingTitle: textField.placeholder) // Needed to update the color
        textField.textColor = .deepGray
        
        //textFieldContainerView.layer.borderColor = UIColor.accentGray.cgColor
    }
    
    func setError(_ error: String?) {
        if let errorMessage = error {
            errorState = true
            checkAccessoryImageView.isHidden = true
            errorLabel.textColor = .errorRed
            
//            textField.floatingLabelTextColor = .errorRed
//            textField.floatingLabelActiveTextColor = .errorRed
//            textField.floatingLabel.textColor = .errorRed
            
            errorLabel.text = String(format: NSLocalizedString("Error: %@", comment: ""), errorMessage)
            self.errorMessage = errorMessage
            errorView.isHidden = false
        } else {
            errorState = false
            
            
//            textField.floatingLabelTextColor = .middleGray
//            textField.floatingLabelActiveTextColor = .primaryColorDark
            if textFieldIsFocused {
                //textField.floatingLabel.textColor = .primaryColorDark
            } else {
                //textField.floatingLabel.textColor = .middleGray
            }
            
            errorLabel.text = nil
            errorView.isHidden = true
            self.errorMessage = ""
        }
    }
    
    func getError() -> String {
        //let fieldTitle = textField.floatingLabel.text?.replacingOccurrences(of: "*", with: "")
        //return errorMessage != "" ? fieldTitle! + " error: " + errorMessage + ". " : ""
        return ""
    }
        
    func setInfoMessage(_ message: String?) {
        if let info = message {
            errorLabel.textColor = .successGreenText
            errorLabel.text = String(format: NSLocalizedString("%@", comment: ""), info)
            errorView.isHidden = false
        } else {
            errorLabel.textColor = .errorRed
            errorLabel.text = nil
            errorView.isHidden = true
        }
    }
    
    func setEnabled(_ enabled: Bool) {
        if enabled {
            isUserInteractionEnabled = true
            textField.isEnabled = true
            setDefaultStyles()
        } else {
            isUserInteractionEnabled = false
            
            textField.text = ""
            textField.sendActions(for: .valueChanged)
            textField.isEnabled = false
            setError(nil)
            setValidated(false)
            
            textFieldContainerView.backgroundColor = UIColor.accentGray.withAlphaComponent(0.08)
//            textField.placeholderColor = .middleGray
//            textField.setPlaceholder(textField.placeholder, floatingTitle: textField.placeholder) // Needed to update the color
        }
    }
    
    func setValidated(_ validated: Bool, accessibilityLabel: String? = nil) {
        if validated {
            setError(nil)
            checkAccessoryImageView.isHidden = false
            checkAccessoryImageView.isAccessibilityElement = true
            if let label = accessibilityLabel {
                checkAccessoryImageView.accessibilityLabel = label
            }
            //textField.isShowingAccessory = true
        } else {
            checkAccessoryImageView.isHidden = true
            checkAccessoryImageView.isAccessibilityElement = false
            //textField.isShowingAccessory = false
        }
    }
    
    func setKeyboardType(_ type: UIKeyboardType) {
        textField.keyboardType = type
        if type == .numberPad || type == .decimalPad || type == .phonePad {
            let done = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""), style: .done, target: self, action: #selector(doneButtonAction))
            addDoneButton(done)
        }
    }
    
    func setKeyboardType(_ type: UIKeyboardType, doneActionTarget: Any, doneActionSelector: Selector) {
        textField.keyboardType = type
        if type == .numberPad || type == .decimalPad || type == .phonePad {
            let done = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""), style: .done, target: doneActionTarget, action: doneActionSelector)
            addDoneButton(done)
        }
    }
    
    private func addDoneButton(_ doneButton: UIBarButtonItem) {
        doneButton.setTitleTextAttributes([.foregroundColor: UIColor.actionBlue], for: .normal)
        
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle = UIBarStyle.default
        doneToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            doneButton
        ]
        doneToolbar.sizeToFit()
        
        textField.inputAccessoryView = doneToolbar
    }
    
    @objc private func doneButtonAction() {
        textField.resignFirstResponder()
    }
    
}

extension Reactive where Base: FloatLabelTextFieldNew {
    
    var isEnabled: Binder<Bool> {
        return Binder(base) { floatLabelTextField, enabled in
            floatLabelTextField.setEnabled(enabled)
        }
    }
    
}
