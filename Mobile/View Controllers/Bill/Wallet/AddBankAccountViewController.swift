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
    
    let disposeBag = DisposeBag()
    
    weak var delegate: AddBankAccountViewControllerDelegate?

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var addBankFormView: AddBankFormView!
    
    var viewModel: AddBankAccountViewModel!
    var accountDetail: AccountDetail!
    var oneTouchPayItem: WalletItem!
    var nicknamesInWallet: [String]!
    
    var saveButton = UIBarButtonItem()
    
    var shouldPopToRootOnSave = false
    var shouldSetOneTouchPayByDefault = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBankFormView.delegate = self
        addBankFormView.viewModel.nicknamesInWallet = nicknamesInWallet
        addBankFormView.oneTouchPaySwitch.setOn(shouldSetOneTouchPayByDefault, animated: false)
        addBankFormView.viewModel.oneTouchPay.value = shouldSetOneTouchPayByDefault
        
        viewModel = AddBankAccountViewModel(walletService: ServiceFactory.createWalletService(), addBankFormViewModel: self.addBankFormView.viewModel)
        viewModel.accountDetail = accountDetail
        viewModel.oneTouchPayItem = oneTouchPayItem
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        title = NSLocalizedString("Add Bank Account", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: #selector(onSavePress))
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        viewModel.saveButtonIsEnabled().bind(to: saveButton.rx.isEnabled).disposed(by: disposeBag)
        
        addBankFormView.oneTouchPayDescriptionLabel.text = viewModel.getOneTouchDisplayString()
        
        bindAccessibility()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    func onSavePress() {
        view.endEditing(true)
        
        var shouldShowOneTouchPayWarning = false
        if viewModel.addBankFormViewModel.oneTouchPay.value {
            if viewModel.oneTouchPayItem != nil {
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
                let completion = {
                    LoadingView.hide()
                    self.delegate?.addBankAccountViewControllerDidAddAccount(self)
                    if self.shouldPopToRootOnSave {
                        self.navigationController?.popToRootViewController(animated: true)
                    } else {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
                if setAsOneTouchPay {
                    self.viewModel.enableOneTouchPay(walletItemID: walletItemResult.walletItemId, onSuccess: completion, onError: { errMessage in
                        //In this case, the card was already saved, so not really an error
                        completion()
                    })
                } else {
                    completion()
                }
            }, onError: { errMessage in
                LoadingView.hide()
                var alertVc: UIAlertController
                if Environment.sharedInstance.opco == .bge {
                    alertVc = UIAlertController(title: NSLocalizedString("Verification Failed", comment: ""), message: NSLocalizedString("There was a problem adding this payment account. Please review your information and try again.", comment: ""), preferredStyle: .alert)
                } else { // Error message comes from Fiserv
                    alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                }
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
            addBankAccount(viewModel.addBankFormViewModel.oneTouchPay.value)
        }
        
    }
    
    func bindAccessibility() {
        addBankFormView.routingNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.addBankFormViewModel.routingNumber.value.isEmpty {
                self.viewModel.addBankFormViewModel.routingNumberIsValid().single().subscribe(onNext: { valid in
                    self.accessibilityErrorLabel()
                }).disposed(by: self.disposeBag)
            }
        }).disposed(by: disposeBag)
        
        addBankFormView.routingNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        addBankFormView.accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.addBankFormViewModel.accountNumber.value.isEmpty {
                self.viewModel.addBankFormViewModel.accountNumberIsValid().single().subscribe(onNext: { valid in
                    self.accessibilityErrorLabel()
                }).disposed(by: self.disposeBag)
            }
        }).disposed(by: disposeBag)
        
        addBankFormView.accountNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        viewModel.addBankFormViewModel.confirmAccountNumberMatches.drive(onNext: { matches in
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        viewModel.addBankFormViewModel.nicknameErrorString.drive(onNext: { valid in
            self.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += addBankFormView.routingNumberTextField.getError()
        message += addBankFormView.accountNumberTextField.getError()
        message += addBankFormView.confirmAccountNumberTextField.getError()
        message += addBankFormView.nicknameTextField.getError()
        
        if message.isEmpty {
            self.saveButton.accessibilityLabel = NSLocalizedString("Save", comment: "")
        } else {
            self.saveButton.accessibilityLabel = NSLocalizedString(message + " Save", comment: "")
        }
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

extension AddBankAccountViewController: AddBankFormViewDelegate {
    func addBankFormViewDidTapRoutingNumberTooltip(_ addBankFormView: AddBankFormView) {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Routing Number", comment: ""), image: #imageLiteral(resourceName: "routing_number_info"), description: NSLocalizedString("This number is used to identify your banking institution. You can find your bank’s nine-digit routing number on the bottom of your paper check.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    func addBankFormViewDidTapAccountNumberTooltip(_ addBankFormView: AddBankFormView) {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Account Number", comment: ""), image: #imageLiteral(resourceName: "account_number_info"), description: NSLocalizedString("This number is used to identify your bank account. You can find your checking account number on the bottom of your paper check following the routing number.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
}
