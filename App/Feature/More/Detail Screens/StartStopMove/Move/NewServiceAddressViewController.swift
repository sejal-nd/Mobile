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
protocol NewServiceAddressDelegate: AnyObject {
    func didSelectNewServiceAddress(_ flowData: MoveServiceFlowData)
}
class NewServiceAddressViewController: KeyboardAvoidingStickyFooterViewController {
    @IBOutlet weak var zipTextField: FloatLabelTextField!
    @IBOutlet weak var continueButton: PrimaryButton!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var noteLabel: UILabel!

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

    @IBOutlet weak var btnSteetAddress: UIButton!
    @IBOutlet weak var btnAppartment: UIButton!
    
    var disposeBag = DisposeBag()
    var viewModel: NewServiceAddressViewModel!

    var isLaunchedFromReviewScreen: Bool = false
    var delegate: NewServiceAddressDelegate? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem?.title = ""
        // Do any additional setup after loading the view.
        navigationBackButton()
        configureTextField()
        setupUIBinding()
        refreshData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseUtility.logScreenView(.moveNewAddressView(className: self.className))
        self.view.endEditing(true)
    }
    
    private func navigationBackButton() {
        self.navigationItem.hidesBackButton = true
        let backButtonIconName = isLaunchedFromReviewScreen ? "ic_close" : "ic_back"
        let backButtonAccesibilityLabel = isLaunchedFromReviewScreen ? "Close" : "Back"
        
        let newBackButton = UIBarButtonItem(image: UIImage(named: backButtonIconName), style: UIBarButtonItem.Style.plain, target: self, action: #selector(NewServiceAddressViewController.back(sender:)))
        newBackButton.accessibilityLabel = backButtonAccesibilityLabel
        self.navigationItem.leftBarButtonItem = newBackButton
        
    }
    @objc func back(sender: UIBarButtonItem) {
           if isLaunchedFromReviewScreen {
               self.dismiss(animated: true, completion: nil)
           } else {
               self.navigationController?.popViewController(animated: true)
           }
       }

    private func setupUIBinding(){
        
        selectedstreetAddressLabel.textColor = .deepGray
        selectedAppartmentLabel.textColor = .deepGray
        zipTextField.textField.textColor = .deepGray

        viewModel.showLoadingState
            .subscribe (onNext: { [weak self] status in
                guard let `self` = self else {return }
                self.loadingIndicator.isHidden = !status
                self.enableStreetColorState(self.viewModel.isZipValidated)
            }).disposed(by: disposeBag)

        viewModel.validateZipResponseEvent.subscribe(onNext: { [weak self] result in
            guard let `self` = self else {return }
            self.enableTextFieldEditing(true)
            if let isZipValidated = result?.isValidZipCode {
                if self.viewModel.isZipValid && !isZipValidated {
                    self.btnSteetAddress.isUserInteractionEnabled = false
                    self.zipTextField.setError(NSLocalizedString("Zip code is invalid or may be in an area not served by BG&E", comment: ""))
                }
            }
        })
        .disposed(by: disposeBag)


        viewModel.appartmentResponseEvent
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if self.viewModel.isZipValidated && self.viewModel.isStreetAddressValid {
                    if let appartment_list = self.viewModel.getAppartmentIDs() {
                        if appartment_list.count == 1 {
                            self.viewModel.setAppartment(appartment_list.first)
                            if let suiteNumber = appartment_list.first?.suiteNumber,let premiseID =  appartment_list.first?.premiseID{
                                self.viewModel.premiseID = premiseID
                                self.viewModel.suiteNumber = suiteNumber
                                self.setAppartment(suiteNumber)
                                self.enableAppartmentColorState(false)
                                 self.viewModel.lookupAddress { _ in } onFailure: { [weak self] error in
                                     self?.apiErrorHandling()
                                 }
                            }
                            else if let premiseID =  appartment_list.first?.premiseID{
                                self.viewModel.premiseID = premiseID
                                self.setAppartment(nil)
                                self.enableAppartmentColorState(false)
                                self.viewModel.lookupAddress { _ in } onFailure: { [weak self] error in
                                    self?.apiErrorHandling()
                                }
                            }
                            else {
                                self.setAppartment(nil)
                            }
                        }
                        else if appartment_list.count > 0 {
                            self.enableAppartmentColorState(true)
                            self.continueButton.isEnabled = self.viewModel.canEnableContinue
                        }
                    }
                }
            })
            .disposed(by: disposeBag)


        viewModel.addressLookUpResponseEvent
            .subscribe(onNext: { [weak self] result in
                guard let `self` = self else {return }

                if let address_response = result?.first, let meterInfo = address_response.meterInfo.first  {
                    if !meterInfo.isResidential {
                        self.noteLabel.isHidden = false
                    }
                }
                self.continueButton.isEnabled = self.viewModel.canEnableContinue
            })
            .disposed(by: disposeBag)


        continueButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self, let addressLookupResponse = self.viewModel.addressLookupResponse.value else { return }
                if self.isLaunchedFromReviewScreen {
                    self.viewModel.moveServiceFlowData.addressLookupResponse = addressLookupResponse
                    self.delegate?.didSelectNewServiceAddress(self.viewModel.moveServiceFlowData)
                    self.dismiss(animated: true, completion: nil)
                } else {
                    let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                    let moveStartServiceViewController = storyboard.instantiateViewController(withIdentifier: "MoveStartServiceViewController") as! MoveStartServiceViewController
                    self.viewModel.moveServiceFlowData.addressLookupResponse = addressLookupResponse
                    moveStartServiceViewController.viewModel = MoveStartServiceViewModel(moveServiceFlowData: self.viewModel.moveServiceFlowData)
                    self.navigationController?.pushViewController(moveStartServiceViewController, animated: true)
                }
            }).disposed(by: disposeBag)
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

        streetAddressFloatingLabel.text = NSLocalizedString("Street Address*", comment: "")
        streetAddressFloatingLabel.font = SystemFont.semibold.of(textStyle: .caption2)
        streetAddressFloatingLabel.textColor = .middleGray
        enableStreetColorState(false)


        appartmentPlaceHolderLabel.font = SystemFont.regular.of(textStyle: .callout)
        appartmentPlaceHolderLabel.textColor = .middleGray
        appartmentPlaceHolderLabel.text = NSLocalizedString("Apt/Unit #* ", comment: "")
        appartmentFloatingLabel.text = NSLocalizedString("Apt/Unit #* ", comment: "")

        appartmentFloatingLabel.font = SystemFont.semibold.of(textStyle: .caption2)
        appartmentFloatingLabel.textColor = .middleGray
        enableAppartmentColorState(false)

        continueButton.isEnabled = viewModel.canEnableContinue


        noteLabel.text = NSLocalizedString("Please note: The address you entered is a commercial address and you’ll be subject to commercial rates. ", comment: "")
        noteLabel.textColor = .deepGray

    }
    func refreshData() {
        viewModel.setAddressData(movepDataFlow: viewModel.moveServiceFlowData)

        zipTextField.textField.text = viewModel.zipCode
        setStreetAddress(viewModel?.streetAddress)
        setAppartment(viewModel?.suiteNumber)
        setAppartmentError(nil)
        enableAppartmentColorState(false)
        if isLaunchedFromReviewScreen {
            continueButton.setTitle(NSLocalizedString("Save Address", comment: ""), for: .normal)
            viewModel.validatedZipCodeResponse.accept(ValidatedZipCodeResponse(isValidZipCode: true))
            enableStreetColorState(viewModel.isZipValidated)
            enableAppartmentColorState(viewModel.isStreetAddressValid)
        } else {
            continueButton.setTitle(NSLocalizedString("Continue", comment: ""), for: .normal)
        }

        continueButton.isEnabled = false
    }
    private func enableTextFieldEditing(_ isEnabled : Bool) {
        zipTextField.isUserInteractionEnabled = isEnabled
        btnSteetAddress.isUserInteractionEnabled = isEnabled
        btnAppartment.isUserInteractionEnabled = isEnabled
    }
    private func enableStreetColorState(_ isEnabled : Bool) {
        if (isEnabled){
            streetAddressSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor:.accentGray, borderWidth: 1.0)
            streetAddressSelectionView.backgroundColor = .white
            streetAddressPlaceHolderLabel.textColor = .middleGray
            streetAddressPlaceHolderLabel.alpha = 1
        }else {
            streetAddressSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor:.accentGray, borderWidth: 1.0)
            streetAddressSelectionView.backgroundColor = .softGray
            streetAddressPlaceHolderLabel.textColor = .middleGray
            streetAddressPlaceHolderLabel.alpha = 0.5
        }
    }
    private func enableAppartmentColorState(_ isEnabled : Bool) {
        if (isEnabled){
            appartmentSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor:.accentGray, borderWidth: 1.0)
            appartmentSelectionView.backgroundColor = .white
            appartmentPlaceHolderLabel.textColor = .middleGray
            appartmentPlaceHolderLabel.alpha = 1
        }else {
            appartmentSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor:.accentGray, borderWidth: 1.0)
            appartmentSelectionView.backgroundColor = .softGray
            appartmentPlaceHolderLabel.textColor = .middleGray
            appartmentPlaceHolderLabel.alpha = 0.5
        }
    }
    private func setAppartmentError(_ error: String?) {
        if let errMsg = error {
            appartmentSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor:.errorRed, borderWidth: 1.0)
            appartmentSelectionView.backgroundColor = .white
            appartmentPlaceHolderLabel.text = errMsg
            appartmentPlaceHolderLabel.textColor = .errorRed
        } else {
            appartmentSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor:.accentGray, borderWidth: 1.0)
            appartmentSelectionView.backgroundColor = .white
            appartmentPlaceHolderLabel.textColor = .deepGray
        }
    }
    private func setStreetAddress(_ message: String?) {
        if let msg = message {
            selectedstreetAddressStackView.isHidden = false
            selectedstreetAddressLabel.text = msg
            streetAddressPlaceHolderLabel.isHidden = true
        } else {
            selectedstreetAddressStackView.isHidden = true
            selectedstreetAddressLabel.text = ""
            streetAddressPlaceHolderLabel.isHidden = false
        }
    }
    private func setAppartment(_ message: String?) {
        if let msg = message {
            selectedAppartmentStackView.isHidden = false
            selectedAppartmentLabel.text = msg
            appartmentPlaceHolderLabel.isHidden = true
        } else {
            selectedAppartmentStackView.isHidden = true
            selectedAppartmentLabel.text = ""
            appartmentPlaceHolderLabel.isHidden = false
        }
    }
    @objc func zipCodeDonePressed() {
        zipTextField.textField.resignFirstResponder()
        if !viewModel.isZipValid {
            zipTextField.setError(NSLocalizedString("Zip code must be 5 digits.", comment: ""))
        } else {
            enableTextFieldEditing(false)
            viewModel.validateZipCode { _ in } onFailure: { [weak self] error in
                self?.apiErrorHandling()
            }
        }
        scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentInset.top), animated: true)
    }
    @IBAction func streetAddressPressed(_ sender: Any) {
        zipTextField.textField.resignFirstResponder()
        if !viewModel.isZipValid {
            zipTextField.setError(NSLocalizedString("Zip code must be 5 digits.", comment: ""))
        } else if !viewModel.isZipValidated {
            enableTextFieldEditing(false)
            viewModel.validateZipCode { _ in } onFailure: { [weak self] error in
                self?.apiErrorHandling()
            }
        } else {
            let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
            let newServiceAddressViewController = storyboard.instantiateViewController(withIdentifier: "AddressSearchViewController") as! AddressSearchViewController
            newServiceAddressViewController.delegate = self
            newServiceAddressViewController.zipcode = viewModel.zipCode
            newServiceAddressViewController.searchType = .street
            newServiceAddressViewController.viewModel.isUnauthMove = viewModel.moveServiceFlowData.unauthMoveData?.isUnauthMove ?? false
            let newServiceAddresNavigationController = LargeTitleNavigationController(rootViewController: newServiceAddressViewController)
            newServiceAddresNavigationController.modalPresentationStyle = .fullScreen
            newServiceAddressViewController.addCloseButton()
            self.navigationController?.present(newServiceAddresNavigationController, animated: true, completion: nil)
        }
    }

    @IBAction func appartmentPressed(_ sender: Any) {
        if !viewModel.isZipValid {
            zipTextField.setError(NSLocalizedString("Zip code must be 5 digits.", comment: ""))
        }
        else if viewModel.isZipValid && !viewModel.isStreetAddressValid {

        }
        else {
            if let appartment_list = self.viewModel.getAppartmentIDs(), appartment_list.count > 1  {
                let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                let newServiceAddressViewController = storyboard.instantiateViewController(withIdentifier: "AddressSearchViewController") as! AddressSearchViewController
                newServiceAddressViewController.delegate = self
                newServiceAddressViewController.zipcode = viewModel.zipCode
                newServiceAddressViewController.searchType = .appartment
                newServiceAddressViewController.listAppartment = viewModel.getAppartmentIDs()?.filter{ ($0.suiteNumber?.count ?? 0) > 0}
                newServiceAddressViewController.viewModel.isUnauthMove = viewModel.moveServiceFlowData.unauthMoveData?.isUnauthMove ?? false
                let newServiceAddresNavigationController = LargeTitleNavigationController(rootViewController: newServiceAddressViewController)
                newServiceAddresNavigationController.modalPresentationStyle = .fullScreen
                newServiceAddressViewController.addCloseButton()
                self.navigationController?.present(newServiceAddresNavigationController, animated: true, completion: nil)
            }
        }
    }
    func clearPreviousSession() {
        viewModel.refreshSession()
        streetAddressPlaceHolderLabel.text = NSLocalizedString("Street Address*", comment: "")
        appartmentPlaceHolderLabel.text = NSLocalizedString("Apt/Unit #* ", comment: "")
        selectedstreetAddressStackView.isHidden = true;
        enableStreetColorState(false)
        enableAppartmentColorState(false)
        setStreetAddress(nil)
        setAppartment(nil)

        noteLabel.isHidden = true;
        continueButton.isEnabled = viewModel.canEnableContinue
    }

    func clearAppartmentSession() {
        viewModel.refreshAppartmentSession()
        appartmentPlaceHolderLabel.text = NSLocalizedString("Apt/Unit #* ", comment: "")
        enableAppartmentColorState(false)
        setAppartment(nil)

        noteLabel.isHidden = true;
        continueButton.isEnabled = viewModel.canEnableContinue
    }

    private func apiErrorHandling() {
        
        let exitAction = UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .default)
        { [weak self] _ in
            guard let `self` = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
        self.loadingIndicator.isHidden = true
        DispatchQueue.main.async {
            self.presentAlert(title: NSLocalizedString("We're experiencing technical issues ", comment: ""),
                               message: NSLocalizedString("We can't retrieve the data you requested. Please try again later. ", comment: ""),
                               style: .alert,
                               actions: [exitAction])
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
            if string.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil {
                if length > 1 && viewModel.isStreetAddressValid {
                    clearPreviousSession()
                }

                if length > 5 {
                    return false
                }
                else if length <= 4 {
                    zipTextField.setError(NSLocalizedString("Zip code must be 5 digits.", comment: ""))
                }
                else {
                    zipTextField.setError(nil)
                    viewModel.zipCode = decimalString
                    enableTextFieldEditing(false)
                    viewModel.validateZipCode { _ in } onFailure: { [weak self] error in
                        self?.apiErrorHandling()
                    }
                    self.btnSteetAddress.isUserInteractionEnabled = false
                    textField.text = decimalString;
                    textField.resignFirstResponder()
                }
            } else {
                if length >= 5 {
                    return false
                }else {
                    let  char = string.cString(using: String.Encoding.utf8)!
                    let isBackSpace = strcmp(char, "\\b")
                    if isBackSpace == -92 {
                        viewModel.zipCode = decimalString
                        if length > 0 {
                            clearPreviousSession()
                        }
                    }else {
                        zipTextField.setError(NSLocalizedString("Only numbers allowed", comment: ""))
                        return false
                    }
                }
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
        if let suiteNumber = result.suiteNumber,let premiseID =  result.premiseID {
            setAppartmentError(nil)
            viewModel.setAppartment(result)
            setAppartment(suiteNumber)
            self.viewModel.lookupAddress { _ in } onFailure: { [weak self] error in
                self?.apiErrorHandling()
            }
        }
    }

    func didSelectStreetAddress(result: String) {
        if !result.isEmpty {
            viewModel.setStreetAddress(result)
            setStreetAddress(result)
             clearAppartmentSession()
            viewModel.fetchAppartment { _ in } onFailure: { [weak self] error in
                self?.apiErrorHandling()
            }
         
        }
    }

}

