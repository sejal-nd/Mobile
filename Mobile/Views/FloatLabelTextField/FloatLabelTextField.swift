//
//  FloatLabelTextField.swift
//  Mobile
//
//  Created by Marc Shilling on 2/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import JVFloatLabeledTextField
import RxSwift
import RxCocoa

class FloatLabelTextField: UIView {
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var textFieldView: UIView!
    @IBOutlet weak var textField: InsetJVFloatLabeledTextField!
    @IBOutlet weak var checkAccessoryImageView: UIImageView!
    @IBOutlet weak var leftColorBar: UIView!
    @IBOutlet weak var bottomColorBar: UIView!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var disabledColorBar: UIView!
    
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
        
        Bundle.main.loadNibNamed(FloatLabelTextField.className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
        
        leftColorBar.backgroundColor = .primaryColor
        bottomColorBar.isHidden = true
        
        errorLabel.textColor = .errorRed
        errorLabel.font = SystemFont.regular.of(textStyle: .footnote)
        errorLabel.text = nil
        errorView.isHidden = true
        
        textField.font = SystemFont.regular.of(textStyle: .title2)
        textField.floatingLabelFont = SystemFont.semibold.of(textStyle: .caption1)
        textField.floatingLabelYPadding = 6
        textField.floatingLabelTextColor = .primaryColorDark
        textField.floatingLabelActiveTextColor = .primaryColorDark
        textField.rx.controlEvent(.editingDidBegin).asObservable().subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            if !self.errorState {
                self.bottomColorBar.backgroundColor = .primaryColor
                self.bottomColorBar.isHidden = false
            }
            self.textFieldIsFocused = true
        }).disposed(by: disposeBag)
        textField.rx.controlEvent(.editingDidEnd).asObservable().subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            if !self.errorState {
                if self.textField.hasText {
                    self.bottomColorBar.backgroundColor = .accentGray
                    self.bottomColorBar.isHidden = false
                } else {
                    self.bottomColorBar.isHidden = true
                }
            }
            self.textFieldIsFocused = false
        }).disposed(by: disposeBag)
        
        setDefaultStyles()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        view.roundCorners([.topLeft, .topRight], radius: 4.0)
    }
    
    func setDefaultStyles() {
        disabledColorBar.isHidden = true
        
        textFieldView.backgroundColor = UIColor.accentGray.withAlphaComponent(0.3)
        
        textField.placeholderColor = .deepGray
        textField.setPlaceholder(textField.placeholder, floatingTitle: textField.placeholder) // Needed to update the color
        textField.textColor = .blackText
    }
    
    func setError(_ error: String?) {
        if let errorMessage = error {
            errorState = true
            checkAccessoryImageView.isHidden = true
            errorLabel.textColor = .errorRed

            leftColorBar.backgroundColor = .errorRed
            bottomColorBar.backgroundColor = .errorRed
            bottomColorBar.isHidden = false
            
            textField.floatingLabelTextColor = .errorRed
            textField.floatingLabelActiveTextColor = .errorRed
            textField.floatingLabel.textColor = .errorRed
            
            errorLabel.text = String(format: NSLocalizedString("Error: %@", comment: ""), errorMessage)
            self.errorMessage = errorMessage
            errorView.isHidden = false
        } else {
            errorState = false
            
            leftColorBar.backgroundColor = .primaryColor
            if textFieldIsFocused {
                bottomColorBar.backgroundColor = .primaryColor
            } else {
                bottomColorBar.backgroundColor = .accentGray
                if !textField.hasText {
                    bottomColorBar.isHidden = true
                }
            }
            
            textField.floatingLabelTextColor = .primaryColorDark
            textField.floatingLabelActiveTextColor = .primaryColorDark
            textField.floatingLabel.textColor = .primaryColorDark
            
            errorLabel.text = nil
            errorView.isHidden = true
            self.errorMessage = ""
        }
    }
    
    func getError() -> String {
        let fieldTitle = textField.floatingLabel.text?.replacingOccurrences(of: "*", with: "")
        return errorMessage != "" ? fieldTitle! + " error: " + errorMessage + ". " : ""
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
            
            disabledColorBar.isHidden = false
            textFieldView.backgroundColor = UIColor.accentGray.withAlphaComponent(0.08)
            textField.placeholderColor = .middleGray
            textField.setPlaceholder(textField.placeholder, floatingTitle: textField.placeholder) // Needed to update the color
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
            textField.isShowingAccessory = true
        } else {
            checkAccessoryImageView.isHidden = true
            checkAccessoryImageView.isAccessibilityElement = false
            textField.isShowingAccessory = false
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

extension Reactive where Base: FloatLabelTextField {
    
    var isEnabled: Binder<Bool> {
        return Binder(base) { floatLabelTextField, enabled in
            floatLabelTextField.setEnabled(enabled)
        }
    }
    
}
