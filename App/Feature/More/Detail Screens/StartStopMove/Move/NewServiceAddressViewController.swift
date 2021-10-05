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

class NewServiceAddressViewController: KeyboardAvoidingStickyFooterViewController {
    @IBOutlet weak var zipTextField: FloatLabelTextField!
    @IBOutlet weak var continueButton: PrimaryButton!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var streetAddressPlaceHolderLabel: UILabel!
    @IBOutlet weak var selectedstreetAddressStackView: UIStackView!
    @IBOutlet weak var selectedstreetAddressLabel: UILabel!
    @IBOutlet weak var streetAddressFloatingLabel: UILabel!
    @IBOutlet weak var streetAddressSelectionView: UIView!

    @IBOutlet weak var appUnitPlaceHolderLabel: UILabel!
    @IBOutlet weak var selectedAppUnitStackView: UIStackView!
    @IBOutlet weak var selectedAppUnitLabel: UILabel!
    @IBOutlet weak var appUnitFloatingLabel: UILabel!
    @IBOutlet weak var appUnitSelectionView: UIView!

    var disposeBag = DisposeBag()

    private var viewModel = NewServiceAddressViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem?.title = ""
        // Do any additional setup after loading the view.

       
        configureTextField()
        setupUI()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    private func configureTextField() {
        zipTextField.placeholder = NSLocalizedString("Zip Code*", comment: "")

        zipTextField.textField.delegate = self
        zipTextField.textField.keyboardType = .numberPad
        zipTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(zipCodeDonePressed))
        zipTextField.textField.isShowingAccessory = true
        zipTextField.textField.textContentType = .postalCode

        streetAddressPlaceHolderLabel.font = SystemFont.regular.of(textStyle: .callout)
        streetAddressPlaceHolderLabel.textColor = .middleGray
        streetAddressPlaceHolderLabel.text = NSLocalizedString("Street Address*", comment: "")

        streetAddressFloatingLabel.font = SystemFont.semibold.of(textStyle: .caption2)
        streetAddressFloatingLabel.textColor = .middleGray

        selectedstreetAddressLabel.font = SystemFont.regular.of(textStyle: .callout)
        selectedstreetAddressLabel.textColor = .middleGray
        changeStreetColorState(isActive: false)

        appUnitPlaceHolderLabel.font = SystemFont.regular.of(textStyle: .callout)
        appUnitPlaceHolderLabel.textColor = .middleGray
        appUnitPlaceHolderLabel.text = NSLocalizedString("Apt/Unit #*", comment: "")

        appUnitFloatingLabel.font = SystemFont.semibold.of(textStyle: .caption2)
        appUnitFloatingLabel.textColor = .middleGray

        selectedAppUnitLabel.font = SystemFont.regular.of(textStyle: .callout)
        selectedAppUnitLabel.textColor = .middleGray

        changeAppUnitColorState(isActive: false)

    }
    private func setupUI() {
        viewModel.showLoadingState
            .subscribe (onNext: { [weak self] status in
                  self?.loadingIndicator.isHidden = !status
            }).disposed(by: disposeBag)

        continueButton.isEnabled = viewModel.canEnableContinue
    }

    private func changeStreetColorState(isActive : Bool) {
        if (isActive){
            streetAddressSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor:.primaryColor, borderWidth: 1.0)
        }else {
            streetAddressSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor:.accentGray, borderWidth: 1.0)
        }
    }
    private func changeAppUnitColorState(isActive : Bool) {
        if (isActive){
            appUnitSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor:.primaryColor, borderWidth: 1.0)
        }else {
            appUnitSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor:.accentGray, borderWidth: 1.0)
        }
    }
    @objc func zipCodeDonePressed() {
        zipTextField.textField.resignFirstResponder()
        if !viewModel.isZipValid {
            zipTextField.setError(NSLocalizedString("Zip  Code must be 5 characters in length", comment: ""))
        }else {
            viewModel.validateZip()
        }
        scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentInset.top), animated: true)
    }
    @IBAction func streetAddressPressed(_ sender: Any) {
        zipTextField.textField.resignFirstResponder()
        if !viewModel.isZipValid {
            zipTextField.setError(NSLocalizedString("Zip  Code must be 5 characters in length", comment: ""))
        } else if !viewModel.isZipValidated {
            viewModel.validateZip()
        }else {
            // navigate to street search

        }
    }
    
    @IBAction func appUnitPressed(_ sender: Any) {
        zipTextField.textField.resignFirstResponder()
        if !viewModel.isZipValid {
            zipTextField.setError(NSLocalizedString("Zip  Code must be 5 characters in length", comment: ""))
        }
        else if (!viewModel.isZipValidated && !viewModel.isStreetAddressValid ){

        }else {
            // navigate to appartment unit search
        }
    }
    
}
extension NewServiceAddressViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)

        if textField == zipTextField.textField {
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
        continueButton.isEnabled = viewModel.canEnableContinue
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
}
