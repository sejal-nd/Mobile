//
//  AddBankFormView.swift
//  Mobile
//
//  Created by Marc Shilling on 7/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AddBankFormView: UIView {

    @IBOutlet weak var view: UIView!
    @IBOutlet weak var checkingSavingsSegmentedControl: SegmentedControl!
    @IBOutlet weak var accountHolderNameTextField: FloatLabelTextField!
    @IBOutlet weak var routingNumberTextField: FloatLabelTextField!
    @IBOutlet weak var routingNumberTooltipButton: UIButton!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var accountNumberTooltipButton: UIButton!
    @IBOutlet weak var confirmAccountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var nicknameTextField: FloatLabelTextField!
    @IBOutlet weak var oneTouchPayView: UIView!
    @IBOutlet weak var oneTouchPayDescriptionLabel: UILabel!
    @IBOutlet weak var oneTouchPaySwitch: Switch!
    @IBOutlet weak var oneTouchPayLabel: UILabel!
    
    let viewModel = AddBankFormViewModel(walletService: ServiceFactory.createWalletService())

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(AddBankFormView.className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
    }
}

extension AddBankFormView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let characterSet = CharacterSet(charactersIn: string)
        if textField == routingNumberTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 9
        } else if textField == accountNumberTextField.textField || textField == confirmAccountNumberTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 17
        }
        return true
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        if textField == routingNumberTextField.textField {
            if textField.text?.characters.count == 9 {
                accountNumberTextField.textField.becomeFirstResponder()
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if Environment.sharedInstance.opco == .bge {
            if textField == accountHolderNameTextField.textField {
                routingNumberTextField.textField.becomeFirstResponder()
            } else if textField == routingNumberTextField.textField {
                accountNumberTextField.textField.becomeFirstResponder()
            } else if textField == accountNumberTextField.textField {
                if confirmAccountNumberTextField.isUserInteractionEnabled {
                    confirmAccountNumberTextField.textField.becomeFirstResponder()
                }
            } else if textField == confirmAccountNumberTextField.textField {
                nicknameTextField.textField.becomeFirstResponder()
            } else if textField == nicknameTextField.textField {
                //self.onSavePress()
            }
        } else {
            if textField == routingNumberTextField.textField {
                accountNumberTextField.textField.becomeFirstResponder()
            } else if textField == accountNumberTextField.textField {
                if confirmAccountNumberTextField.isUserInteractionEnabled {
                    confirmAccountNumberTextField.textField.becomeFirstResponder()
                }
            } else if textField == confirmAccountNumberTextField.textField {
                nicknameTextField.textField.becomeFirstResponder()
            } else if textField == nicknameTextField.textField {
                //self.onSavePress()
            }
        }
        return false
    }
}
