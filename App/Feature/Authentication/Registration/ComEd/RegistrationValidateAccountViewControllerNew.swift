//
//  RegistrationValidateAccountViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol RegistrationViewControllerDelegate: class {
    func registrationViewControllerDidRegister(_ registrationViewController: UIViewController)
}

class RegistrationValidateAccountViewControllerNew: KeyboardAvoidingStickyFooterViewController {

    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var registrationFormView: UIView!

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var accountNumberView: UIView!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextField!
    @IBOutlet weak var identifierTextField: FloatLabelTextField!
    @IBOutlet weak var accountInfoLabel: UILabel!
    @IBOutlet weak var accIdentifierTextField: FloatLabelTextField!

    @IBOutlet weak var personalStackView: UIStackView!
    @IBOutlet weak var accountStackView: UIStackView!

    @IBOutlet weak var illustrationImageView: UIImageView!
    
    @IBOutlet weak var accountIdentifierDescriptionLabel: UILabel!
    @IBOutlet weak var questionMarkButton: UIButton!
    @IBOutlet weak var identifierDescriptionLabel: UILabel!
    
    @IBOutlet weak var segmentContainer: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var segmentedControl: SegmentedControl!
    @IBOutlet weak var accountSegmentControl: SegmentedControl!
    @IBOutlet weak var continueButton: PrimaryButton!
  
    let viewModel = RegistrationViewModel()
    weak var delegate: RegistrationViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Register", comment: "")
        addCloseButton()
        illustrationImageView.isHidden = true
        viewModel.validateAccountContinueEnabled.drive(continueButton.rx.isEnabled).disposed(by: disposeBag)
        
        instructionLabel.textColor = .neutralDark
        accountIdentifierDescriptionLabel.textColor = .neutralDark
        instructionLabel.text = NSLocalizedString("To start, let's find your residential or business service account using your personal/business information or account details.", comment: "")
        instructionLabel.font = .headline
        instructionLabel.setLineHeight(lineHeight: 24)
        accountInfoLabel.textColor = .neutralDark
        let accountInfoDesc = Configuration.shared.opco.isPHI ? NSLocalizedString("Your 11-digit account number", comment: "") : NSLocalizedString("Your 10-digit account number", comment: "")
        accountInfoLabel.text = NSLocalizedString(accountInfoDesc, comment: "")
        
        segmentedControl.items = [NSLocalizedString("Personal", comment: ""),
                                  NSLocalizedString("Account", comment: "")]
        
        accountSegmentControl.items = [NSLocalizedString("SSN/Tax ID", comment: ""),
                                  NSLocalizedString("Zip Code", comment: "")]
        
        configureTextFields()
        stackView.setCustomSpacing(20, after: instructionLabel)
        stackView.setCustomSpacing(20, after: segmentContainer)
        segmentedControl.selectedIndex.accept(.zero)
        accountSegmentControl.selectedIndex.accept(.zero)
        illustrationImageView.image = UIImage(named: "img_resbill")
        viewModel.checkForMaintenance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        GoogleAnalytics.log(event: .registerOffer)
    }
    
    private func configureTextFields() {
        accountNumberTextField.placeholder = NSLocalizedString("Account Number", comment: "")
        accountNumberTextField.textField.autocorrectionType = .no
        accountNumberTextField.setKeyboardType(.numberPad)
        accountNumberTextField.textField.delegate = self
        accountNumberTextField.textField.isShowingAccessory = true
        accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).disposed(by: disposeBag)
        questionMarkButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.accountNumber.asDriver(), viewModel.accountNumberHasValidLength))
            .drive(onNext: { [weak self] accountNumber, hasValidLength in
                guard let self = self else { return }
                if !accountNumber.isEmpty && !hasValidLength {
                    let errorMessage = Configuration.shared.opco.isPHI ? NSLocalizedString("Account number must contain at least 11 digits.", comment: "") : NSLocalizedString("Account number must contain at least 10 digits.", comment: "")
                    self.accountNumberTextField?.setError(errorMessage)
                }
                self.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        
        accountNumberTextField?.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.accountNumberTextField?.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
    
        accIdentifierTextField.textField.autocorrectionType = .no
        accIdentifierTextField.setKeyboardType(.numberPad)
        accIdentifierTextField.textField.delegate = self
        accIdentifierTextField.textField.isShowingAccessory = true
        accIdentifierTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountIdentifierNumber).disposed(by: disposeBag)
        
        accIdentifierTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.accountIdentifierNumber.asDriver(), viewModel.accountIdentifierHasValidLength))
            .drive(onNext: { [weak self] accountIdentifierNumber, hasValidLength in
                guard let self = self else { return }
                if !accountIdentifierNumber.isEmpty && !hasValidLength {
                    let errorMessage = self.viewModel.accountSelectedSegmentIndex.value == 0 ? NSLocalizedString("Last 4 Digits of SSN or Tax ID must contain at least 4 digits.", comment: "") : NSLocalizedString("Zip code must contain at least 5 digits.", comment: "")
                    self.accIdentifierTextField?.setError(errorMessage)
                }
                self.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        
        accIdentifierTextField?.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.accIdentifierTextField?.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        // Phone number
        phoneNumberTextField.placeholder = NSLocalizedString("Primary Phone Number", comment: "")
        phoneNumberTextField.textField.autocorrectionType = .no
        phoneNumberTextField.setKeyboardType(.phonePad)
        phoneNumberTextField.textField.delegate = self
        phoneNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneNumber).disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.phoneNumber.asDriver(), viewModel.phoneNumberHasTenDigits))
            .drive(onNext: { [weak self] phoneNumber, hasTenDigits in
                guard let self = self else { return }
                if !phoneNumber.isEmpty && !hasTenDigits {
                    self.phoneNumberTextField.setError(NSLocalizedString("Phone number must be 10 digits long", comment: ""))
                }
                self.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.phoneNumberTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        var identifierString = "Last 4 digits of your Social Security Number"
        identifierString.append(" or Business Tax ID")

        identifierDescriptionLabel.textColor = .neutralDark
        identifierDescriptionLabel.text = NSLocalizedString(identifierString, comment: "")
        identifierDescriptionLabel.font = .subheadline
        
        let identifierPlaceholder: String
        identifierPlaceholder = NSLocalizedString("SSN/Business Tax ID", comment: "")
        
        identifierTextField.placeholder = NSLocalizedString(identifierPlaceholder, comment: "")
        identifierTextField.textField.autocorrectionType = .no
        identifierTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(onIdentifierKeyboardDonePress))
        identifierTextField.textField.delegate = self
        identifierTextField.textField.rx.text.orEmpty.bind(to: viewModel.identifierNumber).disposed(by: disposeBag)
        
        identifierTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.identifierNumber.asDriver(), viewModel.identifierHasFourDigits, viewModel.identifierIsNumeric))
            .drive(onNext: { [weak self] identifierNumber, hasFourDigits, isNumeric in
                guard let self = self else { return }
                if !identifierNumber.isEmpty {
                    if !hasFourDigits {
                        self.identifierTextField.setError(NSLocalizedString("This number must be 4 digits long", comment: ""))
                    } else if !isNumeric {
                        self.identifierTextField.setError(NSLocalizedString("This number must be numeric", comment: ""))
                    }
                }
                self.accessibilityErrorLabel()
            })
            .disposed(by: disposeBag)
        
        identifierTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.identifierTextField?.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += accountNumberTextField.getError()
        message += phoneNumberTextField.getError()
        message += identifierTextField.getError()
        
        if message.isEmpty {
            continueButton.accessibilityLabel = NSLocalizedString("Continue", comment: "")
        } else {
            continueButton.accessibilityLabel = String(format: NSLocalizedString("%@ Continue", comment: ""), message)
        }
    }
    
    @objc func onIdentifierKeyboardDonePress() {
		viewModel.validateAccountContinueEnabled.asObservable().take(1).asDriver(onErrorDriveWith: .empty())
			.drive(onNext: { [weak self] enabled in
				if enabled {
					self?.onContinuePress()
				} else {
					self?.view.endEditing(true)
				}
			}).disposed(by: disposeBag)
    }
    
    @IBAction func onAccountNumberTooltipPress() {
        let description: String
        switch Configuration.shared.opco {
        case .bge:
            description = NSLocalizedString("Your Customer Account Number may be found in the top right portion on your bill in the bill summary section. Please enter 10-digits including leading zeros.", comment: "")
        case .comEd:
            description = NSLocalizedString("Your Account Number is located in the upper right portion of a residential bill and the upper center portion of a commercial bill. Please enter all 10 digits, including leading zeros, but no dashes.", comment: "")
        case .peco:
            description = NSLocalizedString("Your Account Number is located in the upper left portion of your bill. Please enter all 10 digits, including leading zeroes, but no dashes. If \"SUMM\" appears after your name on your bill, please enter any account from your list of individual accounts.", comment: "")
        case .pepco, .delmarva, .ace:
            description = NSLocalizedString("Your Account Number is located in the upper-left portion of your bill. Please enter all 11 digits, but no spaces.", comment: "")
        }
        let infoModal = InfoModalViewController(title: NSLocalizedString("Find Account Number", comment: ""), image: UIImage(named: "bill_infographic")!, description: description)
        
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    @IBAction func onContinuePress() {
        view.endEditing(true)
        
        LoadingView.show()
        
        viewModel.validateAccount(onSuccess: { [weak self] in
            LoadingView.hide()
            GoogleAnalytics.log(event: .registerAccountValidation)
            if self?.viewModel.hasMultipleAccount ?? false {
                self?.performSegue(withIdentifier: "chooseAccountSegue", sender: self)
            } else {
                let segueIdentifier = FeatureFlagUtility.shared.bool(forKey: .isB2CAuthentication) ? "createCredentialsB2cSegue" : "createCredentialsSegue"
                self?.performSegue(withIdentifier: segueIdentifier, sender: self)
            }
           
        }, onMultipleAccounts:  { [weak self] in
            LoadingView.hide()
            GoogleAnalytics.log(event: .registerAccountValidation)
            
            self?.performSegue(withIdentifier: "bgeAccountNumberSegue", sender: self)
        }, onError: { [weak self] (title, message) in
            LoadingView.hide()
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            
            self?.present(alertController, animated: true, completion: nil)
        })
    }
    
    @IBAction func onSegmentValueChanged(_ sender: SegmentedControl) {
        if sender.selectedIndex.value == .zero {
            accIdentifierTextField.placeholder = NSLocalizedString("Last 4 Digits of SSN or Tax ID", comment: "")
            accIdentifierTextField.textField.text = ""
            accountIdentifierDescriptionLabel.text = NSLocalizedString("Last 4 digits of your Social Security Number or Business Tax ID", comment: "")
            accIdentifierTextField?.setError(nil)
        } else {
            accIdentifierTextField.placeholder = NSLocalizedString("Zip Code", comment: "")
            accIdentifierTextField.textField.text = ""
            accountIdentifierDescriptionLabel.text = NSLocalizedString("5 digit zip code", comment: "")
            accIdentifierTextField?.setError(nil)
        }
        viewModel.accountSelectedSegmentIndex.accept(sender.selectedIndex.value)
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        if let vc = segue.destination as? RegistrationCreateCredentialsViewControllerNew {
            vc.viewModel = viewModel
        } else if let vc = segue.destination as? RegistrationBGEAccountNumberViewController {
            vc.viewModel = viewModel
        } else if let vc = segue.destination as? RegistrationChooseAccountViewController {
            vc.viewModel = viewModel
            vc.delegate = delegate
        } else if let vc = segue.destination as? B2CRegistrationViewController {
            vc.validatedAccount = viewModel.validatedAccountResponse
            vc.delegate = delegate
        }
    }
    
}

extension RegistrationValidateAccountViewControllerNew: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == phoneNumberTextField.textField {
            let components = newString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            
            let decimalString = components.joined(separator: "") as NSString
            let length = decimalString.length
            
            if length > 10 {
                return false
            }
            
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if length - index > 3 {
                let areaCode = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("(%@) ", areaCode)
                index += 3
            }
            if length - index > 3 {
                let prefix = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substring(from: index)
            formattedString.append(remainder)
            textField.text = formattedString as String
            
            textField.sendActions(for: .valueChanged) // Send rx events
            
            return false
        } else if textField == identifierTextField?.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 4
        } else if textField == accountNumberTextField?.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= (Configuration.shared.opco.isPHI ? 11 : 10)
        } else if textField == accIdentifierTextField?.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= (viewModel.accountSelectedSegmentIndex.value == 0 ? 4 : 5)
        }
        
        return true
    }
    
    @IBAction func segmentValueChanged(_ sender: SegmentedControl) {
        if sender.selectedIndex.value == .zero {
            phoneNumberTextField.isHidden = false
            identifierTextField.isHidden = false
            identifierDescriptionLabel.isHidden = false
            accountNumberView.isHidden = true
            accountSegmentControl.isHidden = true
            accountInfoLabel.isHidden = true
            illustrationImageView.isHidden = true
            accountIdentifierDescriptionLabel.isHidden = true
            accIdentifierTextField.isHidden = true
            personalStackView.isHidden = false
            accountStackView.isHidden = true
        } else {
            personalStackView.isHidden = true
            accountStackView.isHidden = false
            accIdentifierTextField.isHidden = false
            accountIdentifierDescriptionLabel.isHidden = false
            accountNumberView.isHidden = false
            accountSegmentControl.isHidden = false
            phoneNumberTextField.isHidden = true
            identifierTextField.isHidden = true
            identifierDescriptionLabel.isHidden = true
            accountInfoLabel.isHidden = false
            illustrationImageView.isHidden = false
        }
        stackView.setCustomSpacing(20, after: accountInfoLabel)
        viewModel.selectedSegmentIndex.accept(sender.selectedIndex.value)
    }
}

// MARK: - CalendarViewDelegate

extension RegistrationValidateAccountViewControllerNew: CalendarViewDelegate {
    func calendarViewController(_ controller: CalendarViewController, isDateEnabled date: Date) -> Bool {
        return true
    }
    
    func calendarViewController(_ controller: CalendarViewController, didSelect date: Date) {
        let components = Calendar.opCo.dateComponents([.year, .month, .day], from: date)
        guard let opCoTimeDate = Calendar.opCo.date(from: components) else { return }
        viewModel.dueDate.accept(opCoTimeDate.isInToday(calendar: .opCo) ? .now : opCoTimeDate)
    }
}
