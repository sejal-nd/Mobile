//
//  FloatLabelTextField.swift
//  Mobile
//
//  Created by Marc Shilling on 2/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import JVFloatLabeledText

class FloatLabelTextField: UIView, UITextFieldDelegate {
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var textField: InsetJVFloatLabeledTextField!
    @IBOutlet weak var checkAccessoryImageView: UIImageView!
    @IBOutlet weak var errorAccessoryImageView: UIImageView!
    @IBOutlet weak var leftColorBar: UIView!
    @IBOutlet weak var bottomColorBar: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var disabledColorBar: UIView!
    
    final let deselectedBottomBarColor = UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 1)
    final let errorColor = UIColor(red: 113/255, green: 0/255, blue: 28/255, alpha: 1)
    
    var errorState = false
    var textFieldIsFocused = false
    
    var borderLayers = [CALayer]()
    
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
        
        errorLabel.textColor = errorColor
        errorLabel.text = nil
        
        textField.floatingLabelFont = UIFont.systemFont(ofSize: 11, weight: UIFontWeightSemibold)
        textField.floatingLabelYPadding = 6
        textField.floatingLabelTextColor = UIColor.primaryColor.darker()
        textField.floatingLabelActiveTextColor = UIColor.primaryColor.darker()
        textField.delegate = self
        
        setDefaultStyles()
    }
    
    func setDefaultStyles() {
        disabledColorBar.isHidden = true
        
        view.backgroundColor = UIColor(red: 215/255, green: 215/255, blue: 215/255, alpha: 0.3)
        
        textField.placeholderColor = UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 1)
        textField.setPlaceholder(textField.placeholder, floatingTitle: textField.placeholder) // Needed to update the color
        textField.textColor = UIColor(red: 35/255, green: 31/255, blue: 32/255, alpha: 1.0)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if !errorState {
            bottomColorBar.backgroundColor = .primaryColor
            bottomColorBar.isHidden = false
        }
        textFieldIsFocused = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if !errorState {
            if textField.hasText {
                bottomColorBar.backgroundColor = deselectedBottomBarColor
                bottomColorBar.isHidden = false
            } else {
                bottomColorBar.isHidden = true
            }
        }
        textFieldIsFocused = false
    }
    
    func setError(_ errorMessage: String?) {
        if errorMessage != nil {
            errorState = true
            checkAccessoryImageView.isHidden = true
            errorAccessoryImageView.isHidden = false

            leftColorBar.backgroundColor = errorColor
            bottomColorBar.backgroundColor = errorColor
            bottomColorBar.isHidden = false
            
            textField.isShowingAccessory = true
            textField.floatingLabelTextColor = errorColor
            textField.floatingLabelActiveTextColor = errorColor
            textField.floatingLabel.textColor = errorColor
        } else {
            errorState = false
            errorAccessoryImageView.isHidden = true
            
            leftColorBar.backgroundColor = .primaryColor
            if textFieldIsFocused {
                bottomColorBar.backgroundColor = .primaryColor
            } else {
                bottomColorBar.backgroundColor = deselectedBottomBarColor
                if !textField.hasText {
                    bottomColorBar.isHidden = true
                }
            }
            
            textField.isShowingAccessory = false
            textField.floatingLabelTextColor = UIColor.primaryColor.darker()
            textField.floatingLabelActiveTextColor = UIColor.primaryColor.darker()
            textField.floatingLabel.textColor = UIColor.primaryColor.darker()
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
