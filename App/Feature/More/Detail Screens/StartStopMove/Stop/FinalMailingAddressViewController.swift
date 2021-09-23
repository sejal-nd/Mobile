//
//  FinalMailingAddressViewController.swift
//  EUMobile
//
//  Created by RAMAITHANI on 08/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

class FinalMailingAddressViewController: KeyboardAvoidingStickyFooterViewController {

    @IBOutlet weak var stateSelectionView: UIView!
    @IBOutlet weak var streetAddressTextField: FloatLabelTextField!
    @IBOutlet weak var cityTextField: FloatLabelTextField!
    @IBOutlet weak var zipTextField: FloatLabelTextField!
    @IBOutlet weak var statePlaceHolderLabel: UILabel!
    @IBOutlet weak var selectedStateStackView: UIStackView!
    @IBOutlet weak var selectedStateLabel: UILabel!
    @IBOutlet weak var stateFloatingLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var continueButton: PrimaryButton!
    
    private var viewModel: FinalMailingAddressViewModel!
    var mailingAddress: MailingAddress? = nil
    var isLaunchedFromReviewScreen: Bool = false
    
    
    @IBAction func stateButtonTapped(_ sender: UIButton) {
        print("State Button Tapped")
        PickerView.showStringPicker(withTitle: NSLocalizedString("Select State", comment: ""),
                                    data: USState.allCases.map { $0.rawValue },
                                    selectedIndex: viewModel.stateSelectedIndex,
                                    onDone: { [weak self] value, index in
                                        DispatchQueue.main.async { [weak self] in
                                            guard let self = self else { return }
                                            self.viewModel.stateSelectedIndex = index
                                            self.viewModel.state = value
                                            self.selectedStateLabel.text = value
                                            self.stateFloatingLabel.isHidden = false
                                            self.selectedStateStackView.isHidden = false
                                            self.statePlaceHolderLabel.isHidden = true
                                            self.selectedStateLabel.textColor = .middleGray
                                        }
                                    },
                                    onCancel: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = FinalMailingAddressViewModel()
        setupUI()
        configureComponentBehavior()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func setupUI() {
        
        streetAddressTextField.placeholder = NSLocalizedString("Street Address*", comment: "")
        cityTextField.placeholder = NSLocalizedString("City*", comment: "")
        zipTextField.placeholder = NSLocalizedString("Zip Code*", comment: "")
        
        statePlaceHolderLabel.font = SystemFont.regular.of(textStyle: .callout)
        statePlaceHolderLabel.textColor = .middleGray
        
        stateFloatingLabel.font = SystemFont.semibold.of(textStyle: .caption2)
        stateFloatingLabel.textColor = .middleGray
        
        selectedStateLabel.font = SystemFont.regular.of(textStyle: .callout)
        selectedStateLabel.textColor = .primaryColor
        
        stateSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
    }
    
    private func configureComponentBehavior() {
        
        streetAddressTextField.textField.returnKeyType = .next
        streetAddressTextField.textField.autocorrectionType = .no
        streetAddressTextField.textField.delegate = self
        
        cityTextField.textField.returnKeyType = .done
        cityTextField.textField.autocorrectionType = .no
        cityTextField.textField.delegate = self
        
        zipTextField.textField.delegate = self
        zipTextField.textField.keyboardType = .numberPad
        zipTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(zipCodeDonePressed))
        
    }
    
    @objc func zipCodeDonePressed() {
        zipTextField.textField.resignFirstResponder()
        scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentInset.top), animated: true)
    }
}

extension FinalMailingAddressViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == zipTextField.textField {
            let components = newString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            
            let decimalString = components.joined(separator: "") as NSString
            let length = decimalString.length
            
            if length > 5 {
               return false
            }
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == streetAddressTextField.textField {
            viewModel.streetAddress = textField.text
            cityTextField.textField.becomeFirstResponder()
        } else if textField == cityTextField.textField {
            viewModel.city = textField.text
            textField.resignFirstResponder()
        } else if textField == zipTextField.textField {
            viewModel.zipCode = textField.text
            textField.resignFirstResponder()
        }
        if viewModel.isStreetAddressValid, viewModel.isCityValid, viewModel.isZipValid {
            continueButton.isEnabled = true
        } else {
            continueButton.isEnabled = false
        }
    }
}
