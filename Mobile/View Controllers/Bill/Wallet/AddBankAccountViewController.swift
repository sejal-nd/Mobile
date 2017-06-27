//
//  AddBankAccountViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

protocol AddBankAccountViewControllerDelegate: class {
    func addBankAccountViewControllerDidAddAccount(_ addBankAccountViewController: AddBankAccountViewController)
}

class AddBankAccountViewController: UIViewController {
    
    // Checking/Savings Segmented Control (BGE ONLY)
    // Bank account holder name (BGE ONLY)
    // Routing Number with question mark
    // Confirm routing number (BGE ONLY)
    // Account number with question mark
    // Confirm account number
    // Nickname (Optional for ComEd/PECO, required for BGE)
    // One touch pay toggle
    
    let disposeBag = DisposeBag()
    
    weak var delegate: AddBankAccountViewControllerDelegate?

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var checkingSavingsSegmentedControl: SegmentedControl!
    @IBOutlet weak var accountHolderNameTextField: FloatLabelTextField!
    @IBOutlet weak var routingNumberTextField: FloatLabelTextField!
    @IBOutlet weak var routingNumberTooltipButton: UIButton!
    @IBOutlet weak var confirmRoutingNumberTextField: FloatLabelTextField!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var accountNumberTooltipButton: UIButton!
    @IBOutlet weak var confirmAccountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var nicknameTextField: FloatLabelTextField!
    @IBOutlet weak var oneTouchPayView: UIView!
    @IBOutlet weak var oneTouchPayDescriptionLabel: UILabel!
    @IBOutlet weak var oneTouchPaySwitch: Switch!
    @IBOutlet weak var oneTouchPayLabel: UILabel!
    
    let viewModel = AddBankAccountViewModel(walletService: ServiceFactory.createWalletService())
    
    let oneTouchPayService = ServiceFactory.createOneTouchPayService()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        title = NSLocalizedString("Add Bank Account", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: #selector(onSavePress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        viewModel.saveButtonIsEnabled().bind(to: saveButton.rx.isEnabled).addDisposableTo(disposeBag)

        checkingSavingsSegmentedControl.items = [NSLocalizedString("Checking", comment: ""), NSLocalizedString("Savings", comment: "")]
        
        accountHolderNameTextField.textField.placeholder = NSLocalizedString("Bank Account Holder Name*", comment: "")
        accountHolderNameTextField.textField.delegate = self
        accountHolderNameTextField.textField.returnKeyType = .next
        
        routingNumberTextField.textField.placeholder = NSLocalizedString("Routing Number*", comment: "")
        routingNumberTextField.textField.delegate = self
        routingNumberTextField.textField.returnKeyType = .next
        routingNumberTextField.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        routingNumberTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        confirmRoutingNumberTextField.textField.placeholder = NSLocalizedString("Confirm Routing Number*", comment: "")
        confirmRoutingNumberTextField.textField.delegate = self
        confirmRoutingNumberTextField.textField.returnKeyType = .next
        confirmRoutingNumberTextField.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        accountNumberTextField.textField.placeholder = NSLocalizedString("Account Number*", comment: "")
        accountNumberTextField.textField.delegate = self
        accountNumberTextField.textField.returnKeyType = .next
        accountNumberTextField.textField.isShowingAccessory = true
        accountNumberTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        confirmAccountNumberTextField.textField.placeholder = NSLocalizedString("Confirm Account Number*", comment: "")
        confirmAccountNumberTextField.textField.delegate = self
        confirmAccountNumberTextField.textField.returnKeyType = .next
        
        nicknameTextField.textField.placeholder = Environment.sharedInstance.opco == .bge ? NSLocalizedString("Nickname*", comment: "") : NSLocalizedString("Nickname (Optional)", comment: "")
        nicknameTextField.textField.autocorrectionType = .no
        nicknameTextField.textField.returnKeyType = .done

        oneTouchPayDescriptionLabel.textColor = .blackText
        oneTouchPayDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        oneTouchPayDescriptionLabel.text = oneTouchPayService.getOneTouchPayDisplayString(forCustomerNumber: viewModel.accountDetail.customerInfo.number)
        oneTouchPayLabel.textColor = .blackText
        oneTouchPayLabel.text = NSLocalizedString("One Touch Pay", comment: "")
        
        if Environment.sharedInstance.opco == .bge {
            oneTouchPayView.isHidden = true // Cannot do One Touch Pay on BGE until the endpoint returns walletItemID
        } else { // BGE only fields should be removed on ComEd/PECO
            checkingSavingsSegmentedControl.isHidden = true
            accountHolderNameTextField.isHidden = true
            confirmRoutingNumberTextField.isHidden = true
        }
        
        bindViewModel()
        bindValidation()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    func onSavePress() {
        view.endEditing(true)
        
        let customerNumber = viewModel.accountDetail.customerInfo.number
        
        var shouldShowOneTouchPayWarning = false
        if viewModel.oneTouchPay.value {
            if oneTouchPayService.oneTouchPayItem(forCustomerNumber: customerNumber) != nil {
                shouldShowOneTouchPayWarning = true
            }
        }
        
        let addBankAccount = { (setAsOneTouchPay: Bool) in
            LoadingView.show()
            self.viewModel.addBankAccount(onDuplicate: { message in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Duplicate Bank Account", comment: ""), message: message, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alertVc, animated: true, completion: nil)
            }, onSuccess: { walletItemResult in
                if setAsOneTouchPay {
                    let accountNumber = self.viewModel.accountNumber.value
                    let last4 = accountNumber.substring(from: accountNumber.index(accountNumber.endIndex, offsetBy: -4))
                    self.oneTouchPayService.setOneTouchPayItem(walletItemID: walletItemResult.walletItemId, maskedWalletItemAccountNumber: last4, paymentCategoryType: .check, forCustomerNumber: customerNumber)
                }
                
                LoadingView.hide()
                self.delegate?.addBankAccountViewControllerDidAddAccount(self)
                _ = self.navigationController?.popViewController(animated: true)
            }, onError: { errMessage in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Verification Failed", comment: ""), message: NSLocalizedString("There was a problem adding this payment account. Please review your information and try again.", comment: ""), preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alertVc, animated: true, completion: nil)
            })
        }
        
        if shouldShowOneTouchPayWarning {
            let alertVc = UIAlertController(title: NSLocalizedString("One Touch Pay", comment: ""), message: NSLocalizedString("Are you sure you want to replace your current One Touch Pay payment account?", comment: ""), preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { _ in
                addBankAccount(true)
            }))
            present(alertVc, animated: true, completion: nil)
        } else {
            addBankAccount(viewModel.oneTouchPay.value)
        }
        
    }
    
    func bindViewModel() {
        checkingSavingsSegmentedControl.selectedIndex.asObservable().bind(to: viewModel.selectedSegmentIndex).addDisposableTo(disposeBag)
        accountHolderNameTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountHolderName).addDisposableTo(disposeBag)
        routingNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.routingNumber).addDisposableTo(disposeBag)
        confirmRoutingNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.confirmRoutingNumber).addDisposableTo(disposeBag)
        accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).addDisposableTo(disposeBag)
        confirmAccountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.confirmAccountNumber).addDisposableTo(disposeBag)
        nicknameTextField.textField.rx.text.orEmpty.bind(to: viewModel.nickname).addDisposableTo(disposeBag)
        oneTouchPaySwitch.rx.isOn.bind(to: viewModel.oneTouchPay).addDisposableTo(disposeBag)
        
        viewModel.confirmRoutingNumberIsEnabled.drive(onNext: { enabled in
            self.confirmRoutingNumberTextField.setEnabled(enabled)
        }).addDisposableTo(disposeBag)
        viewModel.confirmAccountNumberIsEnabled.drive(onNext: { enabled in
            self.confirmAccountNumberTextField.setEnabled(enabled)
        }).addDisposableTo(disposeBag)
    }
    
    func bindValidation() {
        routingNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.routingNumber.value.isEmpty {
                self.viewModel.routingNumberIsValid().single().subscribe(onNext: { valid in
                    if !valid {
                        self.routingNumberTextField.setError(NSLocalizedString("Must be 9 digits", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
        }).addDisposableTo(disposeBag)
        routingNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.routingNumberTextField.setError(nil)
        }).addDisposableTo(disposeBag)
        
        viewModel.confirmRoutingNumberMatches().subscribe(onNext: { matches in
            if !self.viewModel.confirmRoutingNumber.value.isEmpty {
                if matches {
                    self.confirmRoutingNumberTextField.setValidated(true, accessibilityLabel: NSLocalizedString("Fields match", comment: ""))
                } else {
                    self.confirmRoutingNumberTextField.setError(NSLocalizedString("Routing numbers do not match", comment: ""))
                }
            } else {
                self.confirmRoutingNumberTextField.setValidated(false)
                self.confirmRoutingNumberTextField.setError(nil)
            }
        }).addDisposableTo(disposeBag)
        
        accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.accountNumber.value.isEmpty {
                self.viewModel.accountNumberIsValid().single().subscribe(onNext: { valid in
                    if !valid {
                        self.accountNumberTextField.setError(NSLocalizedString("Must be between 8-17 digits", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
        }).addDisposableTo(disposeBag)
        accountNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.accountNumberTextField.setError(nil)
        }).addDisposableTo(disposeBag)
        
        viewModel.confirmAccountNumberMatches().subscribe(onNext: { matches in
            if !self.viewModel.confirmAccountNumber.value.isEmpty {
                if matches {
                    self.confirmAccountNumberTextField.setValidated(true, accessibilityLabel: NSLocalizedString("Fields match", comment: ""))
                } else {
                    self.confirmAccountNumberTextField.setError(NSLocalizedString("Account numbers do not match", comment: ""))
                }
            } else {
                self.confirmAccountNumberTextField.setValidated(false)
                self.confirmAccountNumberTextField.setError(nil)
            }
        }).addDisposableTo(disposeBag)
        
        viewModel.nicknameIsValid().subscribe(onNext: { valid in
            self.nicknameTextField.setError(valid ? nil : NSLocalizedString("Can only contain letters, numbers, and spaces", comment: ""))
        }).addDisposableTo(disposeBag)
    }
    
    @IBAction func onRoutingNumberQuestionMarkPress() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Routing Number", comment: ""), image: #imageLiteral(resourceName: "routing_number_info"), description: NSLocalizedString("This number is used to identify your banking institution. You can find your bank’s nine-digit routing number on the bottom of your paper check.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    @IBAction func onAccountNumberQuestionMarkPress() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Account Number", comment: ""), image: #imageLiteral(resourceName: "account_number_info"), description: NSLocalizedString("This number is used to identify your bank account. You can find your checking account number on the bottom of your paper check following the routing number.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
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

}

extension AddBankAccountViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let characterSet = CharacterSet(charactersIn: string)
        if textField == routingNumberTextField.textField || textField == confirmRoutingNumberTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 9
        } else if textField == accountNumberTextField.textField || textField == confirmAccountNumberTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet)
        }
        return true
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        if textField == routingNumberTextField.textField {
            if textField.text?.characters.count == 9 {
                if Environment.sharedInstance.opco == .bge {
                     confirmRoutingNumberTextField.textField.becomeFirstResponder()
                } else {
                    accountNumberTextField.textField.becomeFirstResponder()
                }
            }
        } else if textField == confirmRoutingNumberTextField.textField {
            if textField.text?.characters.count == 9 {
                accountNumberTextField.textField.becomeFirstResponder()
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if Environment.sharedInstance.opco == .bge {
            if textField == accountHolderNameTextField.textField {
                routingNumberTextField.textField.becomeFirstResponder()
            } else if textField == routingNumberTextField.textField {
                if confirmRoutingNumberTextField.isUserInteractionEnabled {
                    confirmRoutingNumberTextField.textField.becomeFirstResponder()
                }
            } else if textField == confirmRoutingNumberTextField.textField {
                accountNumberTextField.textField.becomeFirstResponder()
            } else if textField == accountNumberTextField.textField {
                if confirmAccountNumberTextField.isUserInteractionEnabled {
                    confirmAccountNumberTextField.textField.becomeFirstResponder()
                }
            } else if textField == confirmAccountNumberTextField.textField {
                nicknameTextField.textField.becomeFirstResponder()
            } else if textField == nicknameTextField.textField {
                self.onSavePress()
            }
        } else {
            if textField == routingNumberTextField.textField {
                accountNumberTextField.textField.becomeFirstResponder()
            } else if textField == accountNumberTextField.textField {
                if confirmAccountNumberTextField.isUserInteractionEnabled {
                    confirmAccountNumberTextField.textField.becomeFirstResponder()
                }
            } else if textField == confirmAccountNumberTextField.textField {
                nicknameTextField.textField.becomeFirstResponder()
            } else if textField == nicknameTextField.textField {
                self.onSavePress()
            }
        }
        return false
    }
}
