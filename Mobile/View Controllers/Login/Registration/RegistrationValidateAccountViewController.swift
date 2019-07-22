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
import Toast_Swift

class RegistrationValidateAccountViewController: UIViewController {

    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var registrationFormView: UIView!

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var accountNumberView: UIView!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextField!
    @IBOutlet weak var ssNumberNumberTextField: FloatLabelTextField!

    @IBOutlet weak var questionMarkButton: UIButton!
    @IBOutlet weak var identifierDescriptionLabel: UILabel?

    let viewModel = RegistrationViewModel(registrationService: ServiceFactory.createRegistrationService(), authenticationService: ServiceFactory.createAuthenticationService())

    var nextButton = UIBarButtonItem()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotificationCenter()
        
        title = NSLocalizedString("Register", comment: "")

        setupNavigationButtons()
        
        populateHelperLabels()
        
        prepareTextFieldsForInput()
        
        viewModel.checkForMaintenance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        GoogleAnalytics.log(event: .registerOffer)
    }
    
    /// Helpers
    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func setupNavigationButtons() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        viewModel.nextButtonEnabled.drive(nextButton.rx.isEnabled).disposed(by: disposeBag)

        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = nextButton
    }
    
    func populateHelperLabels() {
        instructionLabel.textColor = .blackText
        instructionLabel.text = NSLocalizedString("Please help us validate your account", comment: "")
        instructionLabel.font = SystemFont.semibold.of(textStyle: .headline)
        
        var identifierString = "Last 4 Digits of primary account holder’s Social Security Number"
        
        if Environment.shared.opco == .bge {
            identifierString.append(", Business Tax ID, or BGE Pin")
        } else {
            identifierString.append(" or Business Tax ID.")
        }
        
        identifierDescriptionLabel?.text = NSLocalizedString(identifierString,
                                                             comment: "")
        identifierDescriptionLabel?.font = SystemFont.regular.of(textStyle: .subheadline)
    }
    
    func prepareTextFieldsForInput() {
        let opCo = Environment.shared.opco

        // if opco is not BGE, then format it and ready it for usage; else hide it.
        if opCo != .bge {
            accountNumberTextField.textField.placeholder = NSLocalizedString("Account Number*", comment: "")
            accountNumberTextField.textField.autocorrectionType = .no
            accountNumberTextField.setKeyboardType(.numberPad)
            accountNumberTextField.textField.delegate = self
            accountNumberTextField.textField.isShowingAccessory = true
            accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).disposed(by: disposeBag)
            accountNumberTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
            questionMarkButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
			
			accountNumberTextField?.textField.rx.controlEvent(.editingDidEnd).asDriver()
				.withLatestFrom(Driver.zip(viewModel.accountNumber.asDriver(), viewModel.accountNumberHasTenDigits))
				.drive(onNext: { [weak self] accountNumber, hasTenDigits in
					guard let self = self else { return }
					if !accountNumber.isEmpty && !hasTenDigits {
						self.accountNumberTextField?.setError(NSLocalizedString("Account number must be 10 digits long", comment: ""))
					}
					self.accessibilityErrorLabel()
				}).disposed(by: disposeBag)
            
            accountNumberTextField?.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
                self?.accountNumberTextField?.setError(nil)
                self?.accessibilityErrorLabel()
                
            }).disposed(by: disposeBag)
        } else {
            accountNumberView.isHidden = true
        }
        
        phoneNumberTextField.textField.placeholder = NSLocalizedString("Primary Phone Number*", comment: "")
        phoneNumberTextField.textField.autocorrectionType = .no
        phoneNumberTextField.setKeyboardType(.phonePad)
        phoneNumberTextField.textField.delegate = self
        phoneNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneNumber).disposed(by: disposeBag)
		phoneNumberTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
		
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
        
		let ssString: String
        if Environment.shared.opco == .bge {
			ssString = NSLocalizedString("SSN/Business Tax ID/BGE Pin*", comment: "")
		} else {
			ssString = NSLocalizedString("SSN/Business Tax ID*", comment: "")
        }
        
        ssNumberNumberTextField.textField.placeholder = NSLocalizedString(ssString, comment: "")
        ssNumberNumberTextField.textField.autocorrectionType = .no
        ssNumberNumberTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(onIdentifierKeyboardDonePress))
        ssNumberNumberTextField.textField.delegate = self
        ssNumberNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.identifierNumber).disposed(by: disposeBag)
		ssNumberNumberTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
		
		ssNumberNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
			.withLatestFrom(Driver.zip(viewModel.identifierNumber.asDriver(), viewModel.identifierHasFourDigits, viewModel.identifierIsNumeric))
			.drive(onNext: { [weak self] identifierNumber, hasFourDigits, isNumeric in
				guard let self = self else { return }
				if !identifierNumber.isEmpty {
					if !hasFourDigits {
						self.ssNumberNumberTextField.setError(NSLocalizedString("This number must be 4 digits long", comment: ""))
					} else if !isNumeric {
						self.ssNumberNumberTextField.setError(NSLocalizedString("This number must be numeric", comment: ""))
					}
				}
				self.accessibilityErrorLabel()
			})
			.disposed(by: disposeBag)
        
        ssNumberNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.ssNumberNumberTextField?.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
    
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += accountNumberTextField.getError()
        message += phoneNumberTextField.getError()
        message += ssNumberNumberTextField.getError()
        
        if message.isEmpty {
            nextButton.accessibilityLabel = NSLocalizedString("Next", comment: "")
        } else {
            nextButton.accessibilityLabel = String(format: NSLocalizedString("%@ Next", comment: ""), message)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @objc func onIdentifierKeyboardDonePress() {
		viewModel.nextButtonEnabled.asObservable().take(1).asDriver(onErrorDriveWith: .empty())
			.drive(onNext: { [weak self] enabled in
				if enabled {
					self?.onNextPress()
				} else {
					self?.view.endEditing(true)
				}
			}).disposed(by: disposeBag)
    }

    @objc func onCancelPress() {
        // We do this to cover the case where we push RegistrationViewController from LandingViewController.
        // When that happens, we want the cancel action to go straight back to LandingViewController.
        _ = navigationController?.popViewController(animated: true)
    }
    
    @objc func onNextPress() {
        guard nextButton.isEnabled else { return }
        
        view.endEditing(true)
        
        LoadingView.show()
        
        viewModel.validateAccount(onSuccess: { [weak self] in
            LoadingView.hide()
            GoogleAnalytics.log(event: .registerAccountValidation)
            self?.performSegue(withIdentifier: "createCredentialsSegue", sender: self)
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

    // MARK: - ScrollView
    
    @objc func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let safeAreaBottomInset = view.safeAreaInsets.bottom
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: endFrameRect.size.height - safeAreaBottomInset, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        
        if let vc = segue.destination as? RegistrationCreateCredentialsViewController {
            vc.viewModel = viewModel
        } else if let vc = segue.destination as? RegistrationBGEAccountNumberViewController {
            vc.viewModel = viewModel
        }
    }
    
    @IBAction func onAccountNumberTooltipPress() {
        let description: String
        switch Environment.shared.opco {
        case .bge:
            description = NSLocalizedString("Your Customer Account Number may be found in the top right portion on your bill in the bill summary section. Please enter 10-digits including leading zeros.", comment: "")
        case .comEd:
            description = NSLocalizedString("Your Account Number is located in the upper right portion of a residential bill and the upper center portion of a commercial bill. Please enter all 10 digits, including leading zeros, but no dashes.", comment: "")
        case .peco:
            description = NSLocalizedString("Your Account Number is located in the upper left portion of your bill. Please enter all 10 digits, including leading zeroes, but no dashes. If \"SUMM\" appears after your name on your bill, please enter any account from your list of individual accounts.", comment: "")
        }
        let infoModal = InfoModalViewController(title: NSLocalizedString("Find Account Number", comment: ""), image: #imageLiteral(resourceName: "bill_infographic"), description: description)
        
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
}

extension RegistrationValidateAccountViewController: UITextFieldDelegate {
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
        } else if textField == ssNumberNumberTextField?.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 4
        } else if textField == accountNumberTextField?.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 10
        }
        
        return true
    }
    
}
