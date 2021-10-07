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

    @IBOutlet weak var appartmentPlaceHolderLabel: UILabel!
    @IBOutlet weak var selectedAppartmentStackView: UIStackView!
    @IBOutlet weak var selectedAppartmentLabel: UILabel!
    @IBOutlet weak var appartmentFloatingLabel: UILabel!
    @IBOutlet weak var appartmentSelectionView: UIView!

    var disposeBag = DisposeBag()

    private var viewModel = NewServiceAddressViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem?.title = ""
        // Do any additional setup after loading the view.

        navigationBackButton()
        configureTextField()
        setupUIBinding()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.endEditing(true)
    }
    private func navigationBackButton() {
           self.navigationItem.hidesBackButton = true
           let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_back"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(NewServiceAddressViewController.back(sender:)))
           self.navigationItem.leftBarButtonItem = newBackButton
       }
       @objc func back(sender: UIBarButtonItem) {
           self.navigationController?.popViewController(animated: true)
       }

    private func setupUIBinding(){
        viewModel.showLoadingState
            .subscribe (onNext: { [weak self] status in
                self?.loadingIndicator.isHidden = !status
                if let isZipValidated = self?.viewModel.isZipValidated{
                    self?.enableStreetColorState(isZipValidated)
                }

            }).disposed(by: disposeBag)


        viewModel.appartmentResponseEvent
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if self.viewModel.isZipValidated && self.viewModel.isStreetAddressValid{
                    self.enableappartmentColorState(self.viewModel.isStreetAddressValid)

                    self.continueButton.isEnabled = self.viewModel.canEnableContinue

                    if let appartment_list = self.viewModel.getAppartmentIDs(), appartment_list.count == 1 {
                        if let suiteNumber = appartment_list.first?.suiteNumber,let premiseID =  appartment_list.first?.premiseID{
                            self.viewModel.premiseID = premiseID
                            self.appartmentPlaceHolderLabel.text = suiteNumber
                            self.viewModel.validateAddress()
                        }
                    }else {

                    }
                }
            })
            .disposed(by: disposeBag)

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
        enableStreetColorState(false)


        appartmentPlaceHolderLabel.font = SystemFont.regular.of(textStyle: .callout)
        appartmentPlaceHolderLabel.textColor = .middleGray
        appartmentPlaceHolderLabel.text = NSLocalizedString("Apt/Unit #* ", comment: "")

        appartmentFloatingLabel.font = SystemFont.semibold.of(textStyle: .caption2)
        appartmentFloatingLabel.textColor = .middleGray
        enableappartmentColorState(false)

        continueButton.isEnabled = viewModel.canEnableContinue
    }
    private func enableStreetColorState(_ isEnabled : Bool) {
        if (isEnabled){
            streetAddressSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor:.accentGray, borderWidth: 1.0)
            streetAddressSelectionView.backgroundColor = .white
            streetAddressPlaceHolderLabel.textColor = .deepGray
        }else {
            streetAddressSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor:.accentGray, borderWidth: 1.0)
            streetAddressSelectionView.backgroundColor = .softGray
            streetAddressPlaceHolderLabel.textColor = .middleGray
        }
    }
    private func enableappartmentColorState(_ isEnabled : Bool) {
        if (isEnabled){
            appartmentSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor:.accentGray, borderWidth: 1.0)
            appartmentSelectionView.backgroundColor = .white
            appartmentPlaceHolderLabel.textColor = .deepGray
        }else {
            appartmentSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor:.accentGray, borderWidth: 1.0)
            appartmentSelectionView.backgroundColor = .softGray
            appartmentPlaceHolderLabel.textColor = .middleGray
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
        }else if !viewModel.isZipValidated {
            viewModel.validateZip()
        }else {
            let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
            let newServiceAddressViewController = storyboard.instantiateViewController(withIdentifier: "AddressSearchViewController") as! AddressSearchViewController
            newServiceAddressViewController.delegate = self
            newServiceAddressViewController.zipcode = viewModel.zipCode
            newServiceAddressViewController.searchType = .street
            self.navigationController?.pushViewController(newServiceAddressViewController, animated: true)
        }
    }

    @IBAction func appartmentPressed(_ sender: Any) {
        if !viewModel.isZipValid {
            zipTextField.setError(NSLocalizedString("Zip  Code must be 5 characters in length", comment: ""))
        } else {
            let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
            let newServiceAddressViewController = storyboard.instantiateViewController(withIdentifier: "AddressSearchViewController") as! AddressSearchViewController
            newServiceAddressViewController.delegate = self
            newServiceAddressViewController.zipcode = viewModel.zipCode
            newServiceAddressViewController.searchType = .appartment
            newServiceAddressViewController.listAppartment = viewModel.getAppartmentIDs()
            self.navigationController?.pushViewController(newServiceAddressViewController, animated: true)
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
extension NewServiceAddressViewController: AddressSearchDelegate {
    func didSelectAppartment(result: AppartmentResponse) {
        if let suiteNumber = result.suiteNumber,let premiseID =  result.premiseID{
            viewModel.premiseID = premiseID
            appartmentPlaceHolderLabel.text = suiteNumber
            viewModel.validateAddress()
        }

    }

    func didSelectStreetAddress(result: String) {
        if !result.isEmpty {
            viewModel.streetAddress = result
            streetAddressPlaceHolderLabel.text = result
            viewModel.fetchAppartmentDetails()
        }
    }

}

