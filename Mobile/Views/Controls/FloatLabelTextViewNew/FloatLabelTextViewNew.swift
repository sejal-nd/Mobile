//
//  FloatLabelTextViewNew.swift
//  Mobile
//
//  Created by Marc Shilling on 6/26/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class FloatLabelTextViewNew: UIView {
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var textViewContainerView: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var floatLabel: UILabel!
    @IBOutlet weak var floatLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var infoLabel: UILabel!
    
    var textFieldIsFocused = false
    var characterLimit = 250
    
    let disposeBag = DisposeBag()
    
    var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
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
        inflateView()
        
        textView.font = SystemFont.regular.of(textStyle: .title1)
        textView.tintColor = .primaryColor
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 16, bottom: 17, right: 16)
        textView.textContainer.lineFragmentPadding = 0
        
        placeholderLabel.font = SystemFont.regular.of(textStyle: .title1)
        placeholderLabel.textColor = .middleGray
        
        floatLabel.font = SystemFont.semibold.of(textStyle: .caption1)
        floatLabel.textColor = .middleGray
        floatLabel.alpha = 0
        
        infoLabel.textColor = .deepGray
        infoLabel.font = SystemFont.regular.of(textStyle: .footnote)
        infoLabel.text = nil
        infoView.isHidden = true
        
        setDefaultStyles()
        configureStateObservers()
        enforceCharacterLimit()
        updateInfoMessage()
    }
    
    private func inflateView() {
        Bundle.main.loadNibNamed(className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
    }

    private func configureStateObservers() {
        textView.rx.didBeginEditing.asObservable().subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.textFieldIsFocused = true
            self.textViewContainerView.layer.borderColor = UIColor.primaryColor.cgColor
            self.floatLabel.textColor = .primaryColorDark
        }).disposed(by: disposeBag)
        
        textView.rx.didEndEditing.asObservable().subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.textFieldIsFocused = false
            self.textViewContainerView.layer.borderColor = UIColor.accentGray.cgColor
            self.floatLabel.textColor = .middleGray
        }).disposed(by: disposeBag)
        
        textView.rx.didChange.asObservable().subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            
            if self.textView.hasText {
                self.placeholderLabel.isHidden = true
                self.textViewTopConstraint.constant = 24
                self.view.layoutIfNeeded()
                if self.floatLabelTopConstraint.constant != 8 {
                    self.floatLabelTopConstraint.constant = 8
                    UIView.animate(withDuration: 0.3) {
                        self.floatLabel.alpha = 1
                        self.view.layoutIfNeeded()
                    }
                }
            } else {
                self.placeholderLabel.isHidden = false
                self.textViewTopConstraint.constant = 17
                self.view.layoutIfNeeded()
                if self.floatLabelTopConstraint.constant != 16 {
                    self.floatLabelTopConstraint.constant = 16
                    UIView.animate(withDuration: 0.3) {
                        self.floatLabel.alpha = 0
                        self.view.layoutIfNeeded()
                    }
                }
            }
            
            self.enforceCharacterLimit()
            self.updateInfoMessage()
        }).disposed(by: disposeBag)
    }
    
    private func enforceCharacterLimit() {
        if let string = textView.text {
            let length = string.count
            if length >= characterLimit {
                self.textView.text = String(string[..<string.index((string.startIndex), offsetBy: characterLimit)])
            }
        }
    }
    
    private func updateInfoMessage() {
        let remaining = characterLimit - textView.text.count
        setInfoMessage(String.localizedStringWithFormat("%d characters left", remaining))
    }
    
    func setDefaultStyles() {
        textViewContainerView.backgroundColor = .white
        textViewContainerView.fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)
        
        textView.textColor = .deepGray
    }
    
    func setInfoMessage(_ message: String?) {
        if let info = message {
            infoLabel.text = info
            infoView.isHidden = false
        } else {
            infoLabel.text = nil
            infoView.isHidden = true
        }
    }
    
    func setKeyboardType(_ type: UIKeyboardType, doneActionTarget: Any = self, doneActionSelector: Selector = #selector(doneButtonAction)) {
        textView.keyboardType = type
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
        
        textView.inputAccessoryView = doneToolbar
    }
    
    @objc private func doneButtonAction() {
        textView.resignFirstResponder()
    }
    
}
