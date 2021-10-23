//
//  FinalMailingAddressViewController.swift
//  EUMobile
//
//  Created by RAMAITHANI on 08/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

protocol FinalMailingAddressDelegate {
    func mailingAddress(_ address: MailingAddress)
}

//TODO: Handline of the Modal Presentation will be covered as part of the review story.
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
    var isLaunchedFromReviewScreen: Bool = false
    var stopFlowData: StopServiceFlowData!
    var delegate: FinalMailingAddressDelegate? = nil

    @IBAction func stateButtonTapped(_ sender: UIButton) {
        showStatePicker()
    }
    
    @IBAction func continueButtonTapped(_ sender: UIButton) {
        
        guard  let streetAddress = viewModel.streetAddress, let city = viewModel.city, let state = viewModel.state, let zipCode = viewModel.zipCode  else { return }
        let address = MailingAddress(streetAddress: streetAddress, city: city, state: state, zipCode: zipCode, stateSelectedIndex: viewModel.stateSelectedIndex)

        if isLaunchedFromReviewScreen {
            delegate?.mailingAddress(address)
            self.dismiss(animated: true, completion: nil)
        } else {
            let storyboard = UIStoryboard(name: "ISUMStop", bundle: nil)
            let reviewStopServiceViewController = storyboard.instantiateViewController(withIdentifier: "ReviewStopServiceViewController") as! ReviewStopServiceViewController
            reviewStopServiceViewController.delegate = self
            stopFlowData.mailingAddress = address
            reviewStopServiceViewController.stopFlowData = stopFlowData
            self.navigationController?.pushViewController(reviewStopServiceViewController, animated: true)
        }
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
        
        refreshData()
        colorStateBorderGray()
        navigationFlowButton()
    }
    
    func refreshData() {
        
        viewModel.setMailingData(stopDataFlow: stopFlowData)
        
        streetAddressTextField.placeholder = NSLocalizedString("Street Address*", comment: "")
        streetAddressTextField.textField.text = viewModel?.streetAddress
        
        cityTextField.placeholder = NSLocalizedString("City*", comment: "")
        cityTextField.textField.text = viewModel?.city
        
        zipTextField.placeholder = NSLocalizedString("Zip Code*", comment: "")
        zipTextField.textField.text = viewModel?.zipCode
        
        statePlaceHolderLabel.font = SystemFont.regular.of(textStyle: .callout)
        statePlaceHolderLabel.textColor = .middleGray
        statePlaceHolderLabel.text = NSLocalizedString("State*", comment: "")
        
        stateFloatingLabel.font = SystemFont.semibold.of(textStyle: .caption2)
        stateFloatingLabel.textColor = .middleGray
        
        selectedStateLabel.font = SystemFont.regular.of(textStyle: .callout)
        selectedStateLabel.textColor = .middleGray
        if let state = viewModel?.state {
            selectedStateLabel.text = state.rawValue
            statePlaceHolderLabel.isHidden = true
            selectedStateStackView.isHidden = false
        } else {
            selectedStateStackView.isHidden = true
            statePlaceHolderLabel.isHidden = false
            selectedStateLabel.text = nil
        }
        if isLaunchedFromReviewScreen {
            continueButton.setTitle(NSLocalizedString("Save Address", comment: ""), for: .normal)
        } else {
            continueButton.setTitle(NSLocalizedString("Continue", comment: ""), for: .normal)
        }
        continueButton.isEnabled = viewModel.canEnableContinue
    }
    
    private func navigationFlowButton() {
        
        self.navigationItem.hidesBackButton = true
        let backButtonIconName = isLaunchedFromReviewScreen ? "ic_close" : "ic_back"
        let backButtonAccesibilityLabelText = isLaunchedFromReviewScreen ? "Close" : "Back"
        let newBackButton = UIBarButtonItem(image: UIImage(named: backButtonIconName), style: UIBarButtonItem.Style.plain, target: self, action: #selector(FinalMailingAddressViewController.back(sender:)))
        newBackButton.accessibilityLabel = backButtonAccesibilityLabelText
        self.navigationItem.leftBarButtonItem = newBackButton
    }
    
    @objc func back(sender: UIBarButtonItem) {
        
        if isLaunchedFromReviewScreen {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func configureComponentBehavior() {
        
        streetAddressTextField.textField.returnKeyType = .next
        streetAddressTextField.textField.delegate = self
        zipTextField.textField.textContentType = .fullStreetAddress
        
        cityTextField.textField.returnKeyType = .next
        cityTextField.textField.delegate = self
        zipTextField.textField.textContentType = .addressCity
        
        zipTextField.textField.delegate = self
        zipTextField.textField.keyboardType = .numberPad
        zipTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(zipCodeDonePressed))
        zipTextField.textField.isShowingAccessory = true
        zipTextField.textField.textContentType = .postalCode
        
    }
    
    private func showStatePicker() {
        streetAddressTextField.textField.resignFirstResponder()
        cityTextField.textField.resignFirstResponder()
        zipTextField.textField.resignFirstResponder()
        PickerView.showStringPicker(withTitle: NSLocalizedString("Select State", comment: ""),
                                    data: USState.allCases.map { $0.rawValue },
                                    selectedIndex: viewModel.stateSelectedIndex,
                                    onDone: { [weak self] value, index in
                                        DispatchQueue.main.async { [weak self] in
                                            guard let self = self else { return }
                                            self.viewModel.stateSelectedIndex = index
                                            
                                            switch index {
                                            case 1...USState.allCases.count:
                                                self.viewModel.state = USState.allCases[index]
                                                self.selectedStateLabel.text = value
                                                self.selectedStateStackView.isHidden = false
                                                self.statePlaceHolderLabel.isHidden = true
                                            default:
                                                self.statePlaceHolderLabel.isHidden = false
                                                self.selectedStateStackView.isHidden = true
                                                self.selectedStateLabel.text = nil
                                            }
                                            self.continueButton.isEnabled = self.viewModel.canEnableContinue
                                        }
                                    },
                                    onCancel: {
                                        self.continueButton.isEnabled = self.viewModel.canEnableContinue
                                    })
    }
    
    private func colorStateBorderGray() {
        stateSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor:.accentGray, borderWidth: 1.0)
    }
    
    @objc func zipCodeDonePressed() {
        zipTextField.textField.resignFirstResponder()
        if !viewModel.isZipValid {
            zipTextField.setError(NSLocalizedString("Zip  Code must be 5 characters in length", comment: ""))
        }
        scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentInset.top), animated: true)
    }
}

extension FinalMailingAddressViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == streetAddressTextField.textField {
            viewModel.streetAddress = newString
        } else if textField == cityTextField.textField {
            viewModel.city = newString
        } else if textField == zipTextField.textField {
            let components = newString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            let decimalString = components.joined(separator: "") as String
            let length = decimalString.count

            if string.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil {
                if length > 5 {
                    return false
                } else {
                    zipTextField.setError(nil)
                    viewModel.zipCode = decimalString
                }
            } else {
                if length >= 5 {
                    return false
                }else {
                    let  char = string.cString(using: String.Encoding.utf8)!
                    let isBackSpace = strcmp(char, "\\b")
                    if isBackSpace == -92 {
                        viewModel.zipCode = decimalString
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
        if textField == streetAddressTextField.textField {
            cityTextField.textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        continueButton.isEnabled = viewModel.canEnableContinue
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == streetAddressTextField.textField {
            streetAddressTextField.setError(nil)
        } else if textField == cityTextField.textField {
            cityTextField.setError(nil)
        } else if textField == zipTextField.textField {
            zipTextField.setError(nil)
        }
    }
}

extension FinalMailingAddressViewController: FinalMailingAddressDelegate {
    
    func mailingAddress(_ address: MailingAddress) {
        
        self.stopFlowData.mailingAddress = address
        refreshData()
    }
}
