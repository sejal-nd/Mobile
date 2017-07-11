//
//  AccountLookupToolViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class AccountLookupToolViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    let viewModel = AccountLookupToolViewModel(authService: ServiceFactory.createAuthenticationService())
    
    weak var delegate: AccountLookupToolResultViewControllerDelegate?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextField!
    @IBOutlet weak var identifierDescriptionLabel: UILabel!
    @IBOutlet weak var identifierTextField: FloatLabelTextField!
    
    var searchButton = UIBarButtonItem()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)

        title = NSLocalizedString("Account Lookup", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        searchButton = UIBarButtonItem(title: NSLocalizedString("Search", comment: ""), style: .done, target: self, action: #selector(onSearchPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = searchButton
        viewModel.searchButtonEnabled().bind(to: searchButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        identifierDescriptionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        identifierDescriptionLabel.text = NSLocalizedString("Last 4 Digits of primary account holder’s Social Security Number, or Business Tax ID", comment: "")
        
        phoneNumberTextField.textField.placeholder = NSLocalizedString("Primary Phone Number*", comment: "")
        phoneNumberTextField.textField.autocorrectionType = .no
        phoneNumberTextField.textField.returnKeyType = .next
        phoneNumberTextField.textField.delegate = self
        viewModel.phoneNumber.asObservable().bind(to: phoneNumberTextField.textField.rx.text.orEmpty)
            .addDisposableTo(disposeBag)
        phoneNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneNumber).addDisposableTo(disposeBag)
        phoneNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: { _ in
            if self.viewModel.phoneNumber.value.characters.count > 0 {
                self.viewModel.phoneNumberHasTenDigits().single().subscribe(onNext: { valid in
                    if !valid {
                        self.phoneNumberTextField.setError(NSLocalizedString("Phone number must be 10 digits long.", comment: ""))
                    }
                    self.accessibilityErrorLabel()
                    
                }).addDisposableTo(self.disposeBag)
            }
        }).addDisposableTo(disposeBag)
        phoneNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
            self.phoneNumberTextField.setError(nil)
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(disposeBag)
        phoneNumberTextField.textField.sendActions(for: .editingDidEnd) // Load the passed phone number from view model
        
        identifierTextField.textField.placeholder = NSLocalizedString("SSN/Business Tax ID*", comment: "")
        identifierTextField.textField.autocorrectionType = .no
        identifierTextField.textField.returnKeyType = .done
        identifierTextField.textField.delegate = self
        identifierTextField.textField.rx.text.orEmpty.bind(to: viewModel.identifierNumber).addDisposableTo(disposeBag)
        identifierTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: { _ in
            if self.viewModel.identifierNumber.value.characters.count > 0 {
                self.viewModel.identifierHasFourDigits().single().subscribe(onNext: { valid in
                    if !valid {
                        self.identifierTextField.setError(NSLocalizedString("This number must be 4 digits long.", comment: ""))
                    }
                    self.accessibilityErrorLabel()
                    
                }).addDisposableTo(self.disposeBag)
                self.viewModel.identifierIsNumeric().single().subscribe(onNext: { numeric in
                    if !numeric {
                        self.identifierTextField.setError(NSLocalizedString("This number must be numeric.", comment: ""))
                    }
                    self.accessibilityErrorLabel()
                    
                }).addDisposableTo(self.disposeBag)
            }
        }).addDisposableTo(disposeBag)
        identifierTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
            self.identifierTextField.setError(nil)
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(disposeBag)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        if phoneNumberTextField.getError() != "" {
            message += "Phone number error: " + phoneNumberTextField.getError() + ". "
        }
        if identifierTextField.getError() != "" {
            message += "Identifier error: " + identifierTextField.getError() + ". "
        }
        self.searchButton.accessibilityLabel = NSLocalizedString(message, comment: "")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func onCancelPress() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func onSearchPress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.performSearch(onSuccess: {
            LoadingView.hide()
            if self.viewModel.accountLookupResults.count == 1 {
                let selectedAccount = self.viewModel.accountLookupResults.first!
                self.delegate?.accountLookupToolDidSelectAccount(accountNumber: selectedAccount.accountNumber!, phoneNumber: self.viewModel.phoneNumber.value)
                self.navigationController?.popViewController(animated: true)
            } else {
                self.performSegue(withIdentifier: "accountLookupToolResultSegue", sender: self)
            }
        }, onError: { title, message in
            LoadingView.hide()
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        })
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
        if let vc = segue.destination as? AccountLookupToolResultViewController {
            vc.viewModel = viewModel
        }
    }
    
}

extension AccountLookupToolViewController: UITextFieldDelegate {
    
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
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 4
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == phoneNumberTextField.textField {
            identifierTextField.textField.becomeFirstResponder()
        } else if textField == identifierTextField.textField {
            viewModel.searchButtonEnabled().single().subscribe(onNext: { enabled in
                if enabled {
                    self.onSearchPress()
                } else {
                    self.view.endEditing(true)
                }
            }).addDisposableTo(disposeBag)
        }
        return false
    }
}
