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
        
        viewModel = AddBankAccountViewModel(walletService: ServiceFactory.createWalletService(), addBankFormViewModel: addBankFormView.viewModel)
        viewModel.accountDetail = accountDetail
        viewModel.oneTouchPayItem = oneTouchPayItem
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        title = NSLocalizedString("Add Bank Account", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: #selector(onSavePress))
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        viewModel.saveButtonIsEnabled.drive(saveButton.rx.isEnabled).disposed(by: disposeBag)
        
        addBankFormView.oneTouchPayDescriptionLabel.text = viewModel.getOneTouchDisplayString()
        
        bindAccessibility()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func onSavePress() {
        view.endEditing(true)
        
        var shouldShowOneTouchPayWarning = false
        if viewModel.addBankFormViewModel.oneTouchPay.value {
            if viewModel.oneTouchPayItem != nil {
                shouldShowOneTouchPayWarning = true
            }
        }
        
        let addBankAccount = { [weak self] (setAsOneTouchPay: Bool) in
            LoadingView.show()
            guard let self = self else { return }
            self.viewModel.addBankAccount(onDuplicate: { [weak self] message in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Duplicate Bank Account", comment: ""), message: message, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
            }, onSuccess: { [weak self] walletItemResult in
                let completion = { [weak self] in
                    LoadingView.hide()
                    guard let self = self else { return }
                    self.delegate?.addBankAccountViewControllerDidAddAccount(self)
                    if self.shouldPopToRootOnSave {
                        if StormModeStatus.shared.isOn {
                            if let dest = self.navigationController?.viewControllers
                                .first(where: { $0 is StormModeBillViewController }) {
                                self.navigationController?.popToViewController(dest, animated: true)
                            } else {
                                self.navigationController?.popToRootViewController(animated: true)
                            }
                        } else {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    } else {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
                
                if setAsOneTouchPay {
                    self?.viewModel.enableOneTouchPay(walletItemID: walletItemResult.walletItemId, onSuccess: completion, onError: { errMessage in
                        //In this case, the card was already saved, so not really an error
                        completion()
                    })
                } else {
                    completion()
                }
            }, onError: { [weak self] errMessage in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
            })
        }
        
        if shouldShowOneTouchPayWarning {
            let alertVc = UIAlertController(title: NSLocalizedString("Default Payment Method", comment: ""), message: NSLocalizedString("Are you sure you want to replace your default payment method?", comment: ""), preferredStyle: .alert)
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
        Driver.merge(
            addBankFormView.routingNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
                .withLatestFrom(viewModel.addBankFormViewModel.routingNumber.asDriver())
                .filter { !$0.isEmpty }.map(to: ()),
            
            addBankFormView.routingNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().map(to: ()),
            
            addBankFormView.accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
                .withLatestFrom(viewModel.addBankFormViewModel.accountNumber.asDriver())
                .filter { !$0.isEmpty }.map(to: ()),
            
            addBankFormView.accountNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().map(to: ()),
            
            viewModel.addBankFormViewModel.confirmAccountNumberMatches.map(to: ()),
            
            viewModel.addBankFormViewModel.nicknameErrorString.map(to: ())
            
            )
            .drive(onNext: { [weak self] _ in
                self?.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += addBankFormView.routingNumberTextField.getError()
        message += addBankFormView.accountNumberTextField.getError()
        message += addBankFormView.confirmAccountNumberTextField.getError()
        message += addBankFormView.nicknameTextField.getError()
        
        if message.isEmpty {
            saveButton.accessibilityLabel = NSLocalizedString("Save", comment: "")
        } else {
            saveButton.accessibilityLabel = String(format: NSLocalizedString("%@ Save", comment: ""), message)
        }
    }
    
    // MARK: - ScrollView
    
    @objc func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        var safeAreaBottomInset: CGFloat = 0
        if #available(iOS 11.0, *) {
            safeAreaBottomInset = self.view.safeAreaInsets.bottom
        }
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: endFrameRect.size.height - safeAreaBottomInset, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    @objc func keyboardWillHide(notification: Notification) {
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
