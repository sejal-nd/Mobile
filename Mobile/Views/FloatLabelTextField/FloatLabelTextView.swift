//
//  FloatLabeledTextView.swift
//  Mobile
//
//  Created by Kenny Roethel on 9/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import JVFloatLabeledTextField
import RxSwift
import RxCocoa

class FloatLabelTextView: UIView {
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var textFieldView: UIView!
    @IBOutlet weak var textView: JVFloatLabeledTextView!
    @IBOutlet weak var leftColorBar: UIView!
    @IBOutlet weak var bottomColorBar: UIView!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet var borders: [UIView]!
    @IBOutlet var borderWidthConstraints: [NSLayoutConstraint]!
    @IBOutlet weak var disabledColorBar: UIView!
    
    var textFieldIsFocused = false
    var characterLimit = 250
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
        inflateView()
        initializeStatusLabel()
        initializeTextView()
        setDefaultStyles()
        configureStateObservers()
        bottomColorBar.isHidden = true
    }
    
    private func inflateView() {
        Bundle.main.loadNibNamed(FloatLabelTextView.className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
    }
    
    private func initializeStatusLabel() {
        statusLabel.textColor = .deepGray
        statusLabel.font = SystemFont.regular.of(textStyle: .footnote)
        statusLabel.text = nil
        statusView.isHidden = true
        enforceCharacterLimit()
        updateInfoMessage()
    }
    
    private func initializeTextView() {
        textView.font = SystemFont.regular.of(textStyle: .title2)
        textView.floatingLabelFont = SystemFont.semibold.of(textStyle: .caption1)
        textView.floatingLabelYPadding = 6
        textView.floatingLabelTextColor = .clear
        textView.floatingLabelActiveTextColor = .primaryColorDark
        textView.floatingLabelActiveTextColor = .clear
    }
    
    private func configureStateObservers() {
        textView.rx.didBeginEditing.asObservable().subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.bottomColorBar.backgroundColor = .primaryColor
            self.bottomColorBar.isHidden = false
            self.textFieldIsFocused = true
        }).disposed(by: disposeBag)
        
        
        textView.rx.didEndEditing.asObservable().subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            if self.textView.hasText {
                self.bottomColorBar.backgroundColor = .accentGray
                self.bottomColorBar.isHidden = false
            } else {
                self.bottomColorBar.isHidden = true
            }
            self.textFieldIsFocused = false
        }).disposed(by: disposeBag)
        
        textView.rx.didChange.asObservable().subscribe(onNext: {[weak self] _ in
            guard let self = self else { return }
            self.enforceCharacterLimit()
            self.updateInfoMessage()
        }).disposed(by: disposeBag)
    }
    
    private func enforceCharacterLimit() {
        if let string = self.textView.text {
            let length = string.count
            if(length >= characterLimit) {
                self.textView.text = String(string[..<string.index((string.startIndex), offsetBy:characterLimit)])
            }
        }
    }
    
    private func updateInfoMessage() {
        let remaining = characterLimit-self.textView.text.count
        self.setInfoMessage(String(format: "%d characters left", remaining))
    }
    
    func setDefaultStyles() {
        disabledColorBar.isHidden = true
        leftColorBar.backgroundColor = .primaryColor
        
        textFieldView.backgroundColor = UIColor.accentGray.withAlphaComponent(0.3)
        textView.placeholderTextColor = .deepGray
        textView.setPlaceholder(textView.placeholder, floatingTitle: textView.placeholder) // Needed to update the color
        textView.textColor = .blackText
        
        for view in borders {
            view.backgroundColor = .accentGray
        }
        
        borderWidthConstraints.forEach {
            $0.constant = 1.0 / UIScreen.main.scale
        }
    }
    
    private func setInfoMessage(_ message: String?) {
        if let info = message {
            statusLabel.text = String(format: NSLocalizedString("%@", comment: ""), info)
            statusView.isHidden = false
        } else {
            statusLabel.text = nil
            statusView.isHidden = true
        }
    }
    
    func setEnabled(_ enabled: Bool) {
        if enabled {
            isUserInteractionEnabled = true
            textView.isEditable = true
            setDefaultStyles()
        } else {
            isUserInteractionEnabled = false
            textView.text = ""
            textView.isEditable = false
            
            disabledColorBar.isHidden = false
            textFieldView.backgroundColor = UIColor.accentGray.withAlphaComponent(0.08)
            textView.placeholderTextColor = .middleGray
            textView.setPlaceholder(textView.placeholder, floatingTitle: textView.placeholder) // Needed to update the color
        }
    }
    
    func setKeyboardType(_ type: UIKeyboardType) {
        textView.keyboardType = type
        if type == .numberPad || type == .decimalPad || type == .phonePad {
            let done = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""), style: .done, target: self, action: #selector(doneButtonAction))
            addDoneButton(done)
        }
    }
    
    func setKeyboardType(_ type: UIKeyboardType, doneActionTarget: Any, doneActionSelector: Selector) {
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        view.roundCorners([.topLeft, .topRight], radius: 4.0)
    }
    
}

extension Reactive where Base: FloatLabelTextView {
    
    var isEnabled: Binder<Bool> {
        return Binder(base) { floatLabelTextView, enabled in
            floatLabelTextView.setEnabled(enabled)
        }
    }
    
}
