//
//  FloatLabelTextField.swift
//  Mobile
//
//  Created by Marc Shilling on 2/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import JVFloatLabeledText
import RxSwift

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
        textField.rx.controlEvent(.editingDidBegin).asObservable().subscribe(onNext: { _ in
            if !self.errorState {
                self.bottomColorBar.backgroundColor = .primaryColor
                self.bottomColorBar.isHidden = false
            }
            self.textFieldIsFocused = true
        }).addDisposableTo(disposeBag)
        textField.rx.controlEvent(.editingDidEnd).asObservable().subscribe(onNext: { _ in
            if !self.errorState {
                if self.textField.hasText {
                    self.bottomColorBar.backgroundColor = .accentGray
                    self.bottomColorBar.isHidden = false
                } else {
                    self.bottomColorBar.isHidden = true
                }
            }
            self.textFieldIsFocused = false
        }).addDisposableTo(disposeBag)
        
        setDefaultStyles()
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

            leftColorBar.backgroundColor = .errorRed
            bottomColorBar.backgroundColor = .errorRed
            bottomColorBar.isHidden = false
            
            textField.floatingLabelTextColor = .errorRed
            textField.floatingLabelActiveTextColor = .errorRed
            textField.floatingLabel.textColor = .errorRed
            
            errorLabel.text = String(format: NSLocalizedString("Error: %@", comment: ""), errorMessage)
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
        }
    }
    
    func setEnabled(_ enabled: Bool) {
        if enabled {
            isUserInteractionEnabled = true
            setDefaultStyles()
        } else {
            isUserInteractionEnabled = false
            
            textField.text = ""
            textField.sendActions(for: UIControlEvents.valueChanged)
            setError(nil)
            setValidated(false)
            
            disabledColorBar.isHidden = false
            textFieldView.backgroundColor = UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 0.08)
            textField.placeholderColor = UIColor(red: 115/255, green: 115/255, blue: 115/255, alpha: 1) 
            textField.setPlaceholder(textField.placeholder, floatingTitle: textField.placeholder) // Needed to update the color
        }
    }
    
    func setValidated(_ validated: Bool) {
        if validated {
            setError(nil)
            checkAccessoryImageView.isHidden = false
            textField.isShowingAccessory = true
        } else {
            checkAccessoryImageView.isHidden = true
            textField.isShowingAccessory = false
        }
    }
    
}
