//
//  AccountLookupToolViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AccountLookupToolViewController: KeyboardAvoidingStickyFooterViewController {
    
    let disposeBag = DisposeBag()
    
    let viewModel = AccountLookupToolViewModel(authService: ServiceFactory.createAuthenticationService())
    
    weak var delegate: AccountLookupToolResultViewControllerDelegate?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextFieldNew!
    @IBOutlet weak var identifierDescriptionLabel: UILabel!
    @IBOutlet weak var identifierTextField: FloatLabelTextFieldNew!
    @IBOutlet weak var searchButton: PrimaryButtonNew!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCloseButton()
        
        title = NSLocalizedString("Account Lookup Tool", comment: "")
        
        viewModel.searchButtonEnabled.drive(searchButton.rx.isEnabled).disposed(by: disposeBag)
        
        identifierDescriptionLabel.textColor = .deepGray
        identifierDescriptionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        identifierDescriptionLabel.text = NSLocalizedString("Last 4 Digits of primary account holder’s Social Security Number, or Business Tax ID", comment: "")
        
        phoneNumberTextField.placeholder = NSLocalizedString("Primary Phone Number*", comment: "")
        phoneNumberTextField.textField.autocorrectionType = .no
        phoneNumberTextField.setKeyboardType(.phonePad)
        phoneNumberTextField.textField.delegate = self
        viewModel.phoneNumber.asObservable().bind(to: phoneNumberTextField.textField.rx.text.orEmpty)
            .disposed(by: disposeBag)
        phoneNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneNumber).disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.phoneNumber.asDriver(), viewModel.phoneNumberHasTenDigits))
            .filter { !$0.0.isEmpty }
            .drive(onNext: { [weak self] in
                if !$1 {
                    self?.phoneNumberTextField.setError(NSLocalizedString("Phone number must be 10 digits long", comment: ""))
                }
                self?.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.phoneNumberTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        phoneNumberTextField.textField.sendActions(for: .editingDidEnd) // Load the passed phone number from view model
        
        identifierTextField.placeholder = NSLocalizedString("SSN/Business Tax ID*", comment: "")
        identifierTextField.textField.autocorrectionType = .no
        identifierTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(onIndentifierKeyboardDonePress))
        identifierTextField.textField.delegate = self
        identifierTextField.textField.rx.text.orEmpty.bind(to: viewModel.identifierNumber).disposed(by: disposeBag)
        
        identifierTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.identifierNumber.asDriver(), viewModel.identifierHasFourDigits, viewModel.identifierIsNumeric))
            .filter { !$0.0.isEmpty }
            .drive(onNext: { [weak self] identifierNumber, hasFourDigits, isNumeric in
                if !hasFourDigits {
                    self?.identifierTextField.setError(NSLocalizedString("This number must be 4 digits long", comment: ""))
                } else if !isNumeric {
                    self?.identifierTextField.setError(NSLocalizedString("This number must be numeric", comment: ""))
                }
                self?.accessibilityErrorLabel()
            })
            .disposed(by: disposeBag)
        
        identifierTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.identifierTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
    }
    
    private func accessibilityErrorLabel() {
        let errorStr = phoneNumberTextField.getError() + identifierTextField.getError()
        if errorStr.isEmpty {
            searchButton.accessibilityLabel = NSLocalizedString("Search", comment: "")
        } else {
            searchButton.accessibilityLabel = NSLocalizedString(errorStr + " Search", comment: "")
        }
    }
    
    @IBAction func onSearchPress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.performSearch(onSuccess: { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }
            if self.viewModel.accountLookupResults.count == 1 {
                let selectedAccount = self.viewModel.accountLookupResults.first!
                self.delegate?.accountLookupToolDidSelectAccount(accountNumber: selectedAccount.accountNumber!, phoneNumber: self.viewModel.phoneNumber.value)
                self.dismiss(animated: true, completion: nil)
            } else {
                self.performSegue(withIdentifier: "accountLookupToolResultSegue", sender: self)
            }
        }, onError: { [weak self] title, message in
            LoadingView.hide()
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertController, animated: true, completion: nil)
        })
    }
    
    @objc func onIndentifierKeyboardDonePress() {
        viewModel.searchButtonEnabled.asObservable()
            .take(1)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] enabled in
                if enabled {
                    self?.onSearchPress()
                } else {
                    self?.view.endEditing(true)
                }
            }).disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AccountLookupToolResultViewController {
            vc.viewModel = viewModel
            vc.delegate = delegate
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
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 4
        }
        
        return true
    }

}
