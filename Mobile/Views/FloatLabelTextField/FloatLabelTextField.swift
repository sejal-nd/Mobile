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

class FloatLabelTextField: UIView, UITextFieldDelegate {
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var textField: InsetJVFloatLabeledTextField!
    @IBOutlet weak var checkAccessoryImageView: UIImageView!
    @IBOutlet weak var errorAccessoryImageView: UIImageView!
    @IBOutlet weak var leftColorBar: UIView!
    @IBOutlet weak var bottomColorBar: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var disabledColorBar: UIView!
    
    var errorState = false
    var textFieldIsFocused = false
    
    var borderLayers = [CALayer]()
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
        Bundle.main.loadNibNamed("FloatLabelTextField", owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)

        leftColorBar.backgroundColor = .primaryColor
        bottomColorBar.isHidden = true
        
        errorLabel.textColor = .errorRed
        errorLabel.text = nil
        
        textField.floatingLabelFont = UIFont.systemFont(ofSize: 11, weight: UIFontWeightSemibold)
        textField.floatingLabelYPadding = 6
        textField.floatingLabelTextColor = .floatLabelColor
        textField.floatingLabelActiveTextColor = .floatLabelColor
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
                    self.bottomColorBar.backgroundColor = .timberwolf
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
        
        view.backgroundColor = UIColor(red: 215/255, green: 215/255, blue: 215/255, alpha: 0.3)
        
        textField.placeholderColor = UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 1)
        textField.setPlaceholder(textField.placeholder, floatingTitle: textField.placeholder) // Needed to update the color
        textField.textColor = UIColor(red: 35/255, green: 31/255, blue: 32/255, alpha: 1.0)
    }
    
    func setError(_ errorMessage: String?) {
        if errorMessage != nil {
            errorState = true
            checkAccessoryImageView.isHidden = true
            errorAccessoryImageView.isHidden = false

            leftColorBar.backgroundColor = .errorRed
            bottomColorBar.backgroundColor = .errorRed
            bottomColorBar.isHidden = false
            
            textField.isShowingAccessory = true
            textField.floatingLabelTextColor = .errorRed
            textField.floatingLabelActiveTextColor = .errorRed
            textField.floatingLabel.textColor = .errorRed
        } else {
            errorState = false
            errorAccessoryImageView.isHidden = true
            
            leftColorBar.backgroundColor = .primaryColor
            if textFieldIsFocused {
                bottomColorBar.backgroundColor = .primaryColor
            } else {
                bottomColorBar.backgroundColor = .timberwolf
                if !textField.hasText {
                    bottomColorBar.isHidden = true
                }
            }
            
            textField.isShowingAccessory = false
            textField.floatingLabelTextColor = .floatLabelColor
            textField.floatingLabelActiveTextColor = .floatLabelColor
            textField.floatingLabel.textColor = .floatLabelColor
        }
        errorLabel.text = errorMessage
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
            view.backgroundColor = UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 0.08)
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
