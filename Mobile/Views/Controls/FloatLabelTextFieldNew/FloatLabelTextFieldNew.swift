//
//  FloatLabelTextFieldNew.swift
//  Mobile
//
//  Created by Marc Shilling on 6/24/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class FloatLabelTextFieldNew: UIView {
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var textFieldContainerView: UIView!
    @IBOutlet weak var textField: InsetTextField!
    @IBOutlet weak var floatLabel: UILabel!
    @IBOutlet weak var floatLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var checkAccessoryImageView: UIImageView!
    
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    
    var errorState = false
    var textFieldIsFocused = false
    var errorMessage = ""
    
    let disposeBag = DisposeBag()
    
    var placeholder: String? {
        didSet {
            textField.attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.middleGray
            ])
            floatLabel.text = placeholder
        }
    }
    
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
        
        floatLabel.font = SystemFont.semibold.of(textStyle: .caption1)
        floatLabel.textColor = .middleGray
        floatLabel.alpha = 0
        
        textField.font = SystemFont.regular.of(textStyle: .title1)
        textField.tintColor = .primaryColor

        textField.rx.controlEvent(.editingDidBegin).asObservable().subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.textFieldIsFocused = true
            if !self.errorState {
                self.floatLabel.textColor = .primaryColorDark
                self.textFieldContainerView.layer.borderColor = UIColor.primaryColor.cgColor
            }
        }).disposed(by: disposeBag)
        
        textField.rx.controlEvent(.editingDidEnd).asObservable().subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.textFieldIsFocused = false
            if !self.errorState {
                self.floatLabel.textColor = .middleGray
                self.textFieldContainerView.layer.borderColor = UIColor.accentGray.cgColor
            }
        }).disposed(by: disposeBag)
        
        Observable.merge(textField.rx.text.asObservable(),
                         textField.textPublishSubject.asObservable())
            .subscribe(onNext: { [weak self] text in
                guard let self = self else { return }
                self.view.layoutIfNeeded() // So that the textRect shift doesn't animate
                if text?.count > 0 && self.floatLabelTopConstraint.constant != 8 {
                    self.floatLabelTopConstraint.constant = 8
                    UIView.animate(withDuration: 0.3) {
                        self.floatLabel.alpha = 1
                        self.view.layoutIfNeeded()
                    }
                } else if text?.count == 0 && self.floatLabelTopConstraint.constant != 16 {
                    self.floatLabelTopConstraint.constant = 16
                    UIView.animate(withDuration: 0.3) {
                        self.floatLabel.alpha = 0
                        self.view.layoutIfNeeded()
                    }
                }
            }).disposed(by: disposeBag)
        
        setDefaultStyles()
    }
    
    func setDefaultStyles() {
        textFieldContainerView.backgroundColor = .white
        textFieldContainerView.fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)
        
        textField.textColor = .deepGray
        textField.attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: [
            NSAttributedString.Key.foregroundColor: UIColor.middleGray
        ])
    }
    
    func setError(_ error: String?) {
        if let errMsg = error {
            errorState = true
            errorMessage = errMsg
            errorLabel.text = String(format: NSLocalizedString("Error: %@", comment: ""), errorMessage)
            
            errorLabel.textColor = .errorRed
            floatLabel.textColor = .errorRed
            textFieldContainerView.layer.borderColor = UIColor.errorRed.cgColor
            
            errorView.isHidden = false
            checkAccessoryImageView.isHidden = true
        } else {
            errorState = false
            errorMessage = ""
            errorLabel.text = nil
            
            if textFieldIsFocused {
                floatLabel.textColor = .primaryColorDark
                textFieldContainerView.layer.borderColor = UIColor.primaryColor.cgColor
            } else {
                floatLabel.textColor = .middleGray
                textFieldContainerView.layer.borderColor = UIColor.accentGray.cgColor
            }
            
            errorView.isHidden = true
        }
    }
    
    func getError() -> String {
        let fieldTitle = textField.placeholder?.replacingOccurrences(of: "*", with: "")
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
            
            textFieldContainerView.backgroundColor = UIColor.accentGray.withAlphaComponent(0.08)
        
            textField.attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.deepGray.withAlphaComponent(0.5)
            ])
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

extension Reactive where Base: FloatLabelTextFieldNew {
    
    var isEnabled: Binder<Bool> {
        return Binder(base) { floatLabelTextField, enabled in
            floatLabelTextField.setEnabled(enabled)
        }
    }
    
}
