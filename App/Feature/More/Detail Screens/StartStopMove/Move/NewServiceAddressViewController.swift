//
//  NewServiceAddressViewController.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 30/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class NewServiceAddressViewController: UIViewController {
    @IBOutlet weak var zipTextField: FloatLabelTextField!
    @IBOutlet weak var streetAddressTextField: FloatLabelTextField!
    @IBOutlet weak var unit_app_TextField: FloatLabelTextField!
    @IBOutlet weak var continueButton: PrimaryButton!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    var disposeBag = DisposeBag()

    private var viewModel = NewServiceAddressViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        configureTextField()
        setupUI()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    private func configureTextField() {
        zipTextField.placeholder = NSLocalizedString("Zip Code*", comment: "")
        streetAddressTextField.placeholder = NSLocalizedString("Street Address*", comment: "")
        unit_app_TextField.placeholder = NSLocalizedString("Apt/Unit #*", comment: "")


        zipTextField.textField.delegate = self
        zipTextField.textField.keyboardType = .numberPad
        zipTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(zipCodeDonePressed))
        zipTextField.textField.isShowingAccessory = true
        zipTextField.textField.textContentType = .postalCode




        streetAddressTextField.textField.delegate = self
        streetAddressTextField.setKeyboardType(.default, doneActionTarget: self, doneActionSelector: #selector(streetAddressDonePressed))
        zipTextField.textField.isShowingAccessory = true
        zipTextField.textField.textContentType = .addressCityAndState


        unit_app_TextField.textField.delegate = self
        unit_app_TextField.setKeyboardType(.default, doneActionTarget: self, doneActionSelector: #selector(streetAddressDonePressed))
        unit_app_TextField.textField.isShowingAccessory = true
        unit_app_TextField.textField.textContentType = .addressCityAndState

    }
    private func setupUI() {
        viewModel.showLoadingState
            .subscribe (onNext: { [weak self] status in
                self?.loadingIndicator.isHidden = !status
            }).disposed(by: disposeBag)


        continueButton.isEnabled = viewModel.canEnableContinue
    }


    @objc func zipCodeDonePressed() {
        zipTextField.textField.resignFirstResponder()
        if !viewModel.isZipValid {
            zipTextField.setError(NSLocalizedString("Zip  Code must be 5 characters in length", comment: ""))
        }else {
            viewModel.validateZip()
        }
    }
    @objc func streetAddressDonePressed() {
        zipTextField.textField.resignFirstResponder()
        if !viewModel.isZipValid {
            zipTextField.setError(NSLocalizedString("Zip  Code must be 5 characters in length", comment: ""))
        }else {
           //

        }

    }
}
extension NewServiceAddressViewController: UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == streetAddressTextField.textField {
            if (!viewModel.isZipValid && !viewModel.isZipValidated){
                return false
            }
        }
        else if textField == unit_app_TextField.textField {
            if (!viewModel.isZipValid && !viewModel.isZipValidated && !viewModel.isStreetAddressValid ){
                return false
            }
        }
        return true
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)

        if textField == streetAddressTextField.textField {
            viewModel.streetAddress = newString
        } else if textField == zipTextField.textField {
            let components = newString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            let decimalString = components.joined(separator: "") as String
            let length = decimalString.count

            if length > 5 {
                return false
            }
            else if length <= 4 {
                zipTextField.setError(NSLocalizedString("Zip  Code must be 5 characters in length", comment: ""))
            }
            else {
                zipTextField.setError(nil)
                viewModel.zipCode = decimalString
                viewModel.validateZip()
                textField.text = decimalString;
                textField.resignFirstResponder()
            }
        }
        continueButton.isEnabled = viewModel.canEnableContinue
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == streetAddressTextField.textField {
            unit_app_TextField.textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        continueButton.isEnabled = viewModel.canEnableContinue
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == streetAddressTextField.textField {
            streetAddressTextField.setError(nil)
        } else if textField == zipTextField.textField {
            zipTextField.setError(nil)
        }
    }
}
