//
//  ForgotUsernameViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ForgotUsernameViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextField!
    @IBOutlet weak var identifierDescriptionLabel: UILabel?
    @IBOutlet weak var identifierTextField: FloatLabelTextField?
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField?
    @IBOutlet weak var accountLookupToolButton: UIButton?
    @IBOutlet weak var accountNumberTooltipButton: UIButton?
    
    let viewModel = ForgotUsernameViewModel(authService: ServiceFactory.createAuthenticationService())
    
    let disposeBag = DisposeBag()
    var nextButton = UIBarButtonItem()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        title = NSLocalizedString("Forgot Username", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = nextButton
        viewModel.nextButtonEnabled.drive(nextButton.rx.isEnabled).disposed(by: disposeBag)
        
        instructionLabel.textColor = .blackText
        instructionLabel.font = SystemFont.semibold.of(textStyle: .headline)
        instructionLabel.text = NSLocalizedString("Please help us validate your account", comment: "")
        identifierDescriptionLabel?.font = SystemFont.regular.of(textStyle: .subheadline)
        identifierDescriptionLabel?.text = NSLocalizedString("Last 4 Digits of primary account holder’s Social Security Number, Business Tax ID, or BGE PIN", comment: "")
        
        phoneNumberTextField.textField.placeholder = NSLocalizedString("Primary Phone Number*", comment: "")
        phoneNumberTextField.textField.autocorrectionType = .no
        phoneNumberTextField.setKeyboardType(.phonePad)
        phoneNumberTextField.textField.delegate = self
        phoneNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneNumber).disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.phoneNumber.asDriver(), viewModel.phoneNumberHasTenDigits))
            .drive(onNext: { [weak self] phoneNumber, hasTenDigits in
                guard let `self` = self else { return }
                if !phoneNumber.isEmpty {
                    if !hasTenDigits {
                        self.phoneNumberTextField.setError(NSLocalizedString("Phone number must be 10 digits long.", comment: ""))
                    } else {
                        self.phoneNumberTextField.setError(nil)
                    }
                }
                self.accessibilityErrorLabel()
            })
            .disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] _ in
            self?.phoneNumberTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        identifierTextField?.textField.placeholder = NSLocalizedString("SSN/Business Tax ID/BGE Pin*", comment: "")
        identifierTextField?.textField.autocorrectionType = .no
        identifierTextField?.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(onIdentifierAccountNumberKeyboardDonePress))
        identifierTextField?.textField.delegate = self
        identifierTextField?.textField.rx.text.orEmpty.bind(to: viewModel.identifierNumber).disposed(by: disposeBag)
        
        identifierTextField?.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.identifierNumber.asDriver(), viewModel.identifierHasFourDigits, viewModel.identifierIsNumeric))
            .drive(onNext: { [weak self] identifierNumber, hasFourDigits, isNumeric in
                guard let `self` = self else { return }
                if !identifierNumber.isEmpty {
                    if !hasFourDigits {
                        self.identifierTextField?.setError(NSLocalizedString("This number must be 4 digits long.", comment: ""))
                    } else if !isNumeric {
                        self.identifierTextField?.setError(NSLocalizedString("This number must be numeric.", comment: ""))
                    } else {
                        self.identifierTextField?.setError(nil)
                    }
                }
                self.accessibilityErrorLabel()
            })
            .disposed(by: disposeBag)
        
        identifierTextField?.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] _ in
            self?.identifierTextField?.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        accountNumberTextField?.textField.placeholder = NSLocalizedString("Account Number*", comment: "")
        accountNumberTextField?.textField.autocorrectionType = .no
        accountNumberTextField?.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(onIdentifierAccountNumberKeyboardDonePress))
        accountNumberTextField?.textField.delegate = self
        accountNumberTextField?.textField.isShowingAccessory = true
        accountNumberTextField?.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).disposed(by: disposeBag)
        
        accountNumberTextField?.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.accountNumber.asDriver(), viewModel.accountNumberHasTenDigits))
            .drive(onNext: { [weak self] accountNumber, hasTenDigits in
                guard let `self` = self else { return }
                if !accountNumber.isEmpty {
                    if !hasTenDigits {
                        self.accountNumberTextField?.setError(NSLocalizedString("Account number must be 10 digits long.", comment: ""))
                    } else {
                        self.accountNumberTextField?.setError(nil)
                    }
                }
                self.accessibilityErrorLabel()
            })
            .disposed(by: disposeBag)
        
        accountNumberTextField?.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] _ in
            self?.accountNumberTextField?.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        accountNumberTooltipButton?.accessibilityLabel = NSLocalizedString("Tool Tip", comment: "")
        
        accountLookupToolButton?.setTitle(NSLocalizedString("Account Lookup Tool", comment: ""), for: .normal)
        accountLookupToolButton?.setTitleColor(.actionBlue, for: .normal)
        accountLookupToolButton?.titleLabel?.font = SystemFont.bold.of(textStyle: .headline)
        accountLookupToolButton?.accessibilityLabel = NSLocalizedString("Account lookup tool", comment: "")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        dLog()
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += phoneNumberTextField.getError()
        message += identifierTextField != nil ? (identifierTextField?.getError())! : ""
        message += accountNumberTextField != nil ? (accountNumberTextField?.getError())! : ""
        
        if message.isEmpty {
            nextButton.accessibilityLabel = NSLocalizedString("Next", comment: "")
        } else {
            nextButton.accessibilityLabel = NSLocalizedString(message + " Next", comment: "")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.view.backgroundColor = .primaryColor // This prevents a black color from appearing during the transition between `isTranslucent = false` and `isTranslucent = true`
        navigationController?.navigationBar.barTintColor = .primaryColor
        navigationController?.navigationBar.isTranslucent = false

        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: OpenSans.bold.of(size: 18)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func onCancelPress() {
        // We do this to cover the case where we push ForgotUsernameViewController from ForgotPasswordViewController.
        // When that happens, we want the cancel action to go straight back to LoginViewController.
        for vc in (navigationController?.viewControllers)! {
            guard let loginVC = vc as? LoginViewController else {
                continue
            }
            navigationController?.popToViewController(loginVC, animated: true)
            break
        }
    }
    
    func onNextPress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.validateAccount(onSuccess: { [weak self] in
            LoadingView.hide()
            self?.performSegue(withIdentifier: "forgotUsernameResultSegue", sender: self)
            Analytics().logScreenView(AnalyticsPageView.ForgotUsernameCompleteAccountValidation.rawValue)
        }, onNeedAccountNumber: { [weak self] in
            LoadingView.hide()
            self?.performSegue(withIdentifier: "bgeAccountNumberSegue", sender: self)
        }, onError: { [weak self] (title, message) in
            LoadingView.hide()
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertController, animated: true, completion: nil)
        })
    }
    
    @IBAction func onAccountNumberTooltipPress() {
        let description: String
        switch Environment.sharedInstance.opco {
        case .bge:
            description = NSLocalizedString("Your Customer Account Number can be found in the lower right portion of your bill. Please enter 10-digits including leading zeros.", comment: "")
        case .comEd:
            description = NSLocalizedString("Your Account Number is located in the upper right portion of a residential bill and the upper center portion of a commercial bill. Please enter all 10 digits, including leading zeros, but no dashes.", comment: "")
        case .peco:
            description = NSLocalizedString("It is located in the upper right portion of your bill. Please enter all 10 digits, including leading zeroes, but no dashes. If \"SUMM\" appreas after your name on your bill, please enter any account from your list of individual accounts.", comment: "")
        }
        let infoModal = InfoModalViewController(title: NSLocalizedString("Where to Look for Your Account Number", comment: ""), image: #imageLiteral(resourceName: "bill_infographic"), description: description)
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    func onIdentifierAccountNumberKeyboardDonePress() {
        viewModel.nextButtonEnabled.asObservable().take(1).asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] enabled in
                if enabled {
                    self?.onNextPress()
                } else {
                    self?.view.endEditing(true)
                }
            }).disposed(by: disposeBag)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - ScrollView
    
    func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let insets = UIEdgeInsetsMake(0, 0, endFrameRect.size.height, 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        
        if let vc = segue.destination as? ForgotUsernameBGEAccountNumberViewController {
            vc.viewModel.phoneNumber.value = viewModel.phoneNumber.value
            vc.viewModel.identifierNumber.value = viewModel.identifierNumber.value
        } else if let vc = segue.destination as? AccountLookupToolViewController {
            vc.delegate = self
            vc.viewModel.phoneNumber.value = viewModel.phoneNumber.value
        } else if let vc = segue.destination as? ForgotUsernameResultViewController {
            vc.viewModel = viewModel
        }
    }
    
}

extension ForgotUsernameViewController: AccountLookupToolResultViewControllerDelegate {

    func accountLookupToolDidSelectAccount(accountNumber: String, phoneNumber: String) {
        phoneNumberTextField.textField.text = phoneNumber
        phoneNumberTextField.textField.sendActions(for: .editingDidEnd)
        
        accountNumberTextField?.textField.text = accountNumber
        accountNumberTextField?.textField.sendActions(for: .editingDidEnd)
    }
    
}

extension ForgotUsernameViewController: UITextFieldDelegate {
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
            return newString.characters.count <= 4
        } else if textField == accountNumberTextField?.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 10
        }
        
        return true
    }
    
}
