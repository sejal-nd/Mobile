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
    @IBOutlet weak var leftColorBar: UIView!
    @IBOutlet weak var bottomColorBar: UIView!
    
    final let deselectedBottomBarColor = UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 1)
    
    final let deselectedTextColor = UIColor(red: 10/255, green: 10/255, blue: 10/255, alpha: 1.0)
    final let deselectedFont = UIFont.systemFont(ofSize: 17)
    final let selectedFont = UIFont.systemFont(ofSize: 17, weight: UIFontWeightMedium)
    
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
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(red: 236/255, green: 236/255, blue: 236/255, alpha: 1).cgColor
        view.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        addSubview(view)

        leftColorBar.backgroundColor = .primaryColor
        bottomColorBar.isHidden = true
        
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        textField.floatingLabelYPadding = 6
        textField.floatingLabelTextColor = UIColor.primaryColor.darker(by: 30)
        textField.floatingLabelActiveTextColor = UIColor.primaryColor.darker(by: 30)
        textField.floatingLabelFont = UIFont.boldSystemFont(ofSize: 10)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        bottomColorBar.backgroundColor = .primaryColor
        bottomColorBar.isHidden = false
        
        textFieldDidChange(textField: textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.textColor = deselectedTextColor
        textField.font = deselectedFont
        
        if textField.hasText {
            bottomColorBar.backgroundColor = deselectedBottomBarColor
        } else {
            bottomColorBar.isHidden = true
        }
    }
    
    func textFieldDidChange(textField: UITextField) {
        if textField.hasText {
            textField.textColor = .black
            textField.font = selectedFont
        } else {
            textField.textColor = deselectedTextColor
            textField.font = deselectedFont
        }
    }
    

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
