//
//  AddCreditCardViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import AVFoundation


protocol AddCreditCardViewControllerDelegate: class {
    func addCreditCardViewControllerDidAddAccount(_ addCreditCardViewController: AddCreditCardViewController)
}

class AddCreditCardViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    weak var delegate: AddCreditCardViewControllerDelegate?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var addCardFormView: AddCardFormView!
    
    var cardIOViewController: CardIOPaymentViewController!
    
    var viewModel: AddCreditCardViewModel!
    var accountDetail: AccountDetail!
    var oneTouchPayItem: WalletItem!
    var nicknamesInWallet: [String]!
    
    var saveButton = UIBarButtonItem()
    
    var shouldPopToRootOnSave = false
    var shouldSetOneTouchPayByDefault = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCardFormView.delegate = self
        addCardFormView.viewModel.nicknamesInWallet = nicknamesInWallet
        addCardFormView.oneTouchPaySwitch.setOn(shouldSetOneTouchPayByDefault, animated: false)
        addCardFormView.viewModel.oneTouchPay.value = shouldSetOneTouchPayByDefault
        
        viewModel = AddCreditCardViewModel(walletService: ServiceFactory.createWalletService(), addCardFormViewModel: addCardFormView.viewModel)
        viewModel.accountDetail = accountDetail
        viewModel.oneTouchPayItem = oneTouchPayItem
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        title = NSLocalizedString("Add Card", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: #selector(onSavePress))
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        viewModel.saveButtonIsEnabled.drive(saveButton.rx.isEnabled).disposed(by: disposeBag)

        configureCardIO()
        
        addCardFormView.oneTouchPayDescriptionLabel.text = viewModel.getOneTouchDisplayString()

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
        if viewModel.addCardFormViewModel.oneTouchPay.value {
            if viewModel.oneTouchPayItem != nil {
                shouldShowOneTouchPayWarning = true
            }
        }
        
        let addCreditCard = { [weak self] (setAsOneTouchPay: Bool) in
            LoadingView.show()
            self?.viewModel.addCreditCard(onDuplicate: { message in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Duplicate Card", comment: ""), message: message, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
            }, onSuccess: { walletItemResult in
                let completion = {
                    LoadingView.hide()
                    guard let self = self else { return }
                    self.delegate?.addCreditCardViewControllerDidAddAccount(self)
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
            }, onError: { errMessage in
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
                addCreditCard(true)
            }))
            present(alertVc, animated: true, completion: nil)
        } else {
            addCreditCard(viewModel.addCardFormViewModel.oneTouchPay.value)
        }
        
    }
    
    func bindAccessibility() {
        Driver.merge(
            addCardFormView.expMonthTextField.textField.rx.controlEvent(.editingDidEnd).asDriver(),
            addCardFormView.expMonthTextField.textField.rx.controlEvent(.editingDidBegin).asDriver(),
            addCardFormView.cardNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver(),
            addCardFormView.cardNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver(),
            addCardFormView.expYearTextField.textField.rx.controlEvent(.editingDidEnd).asDriver(),
            addCardFormView.expYearTextField.textField.rx.controlEvent(.editingDidBegin).asDriver(),
            addCardFormView.cvvTextField.textField.rx.controlEvent(.editingDidEnd).asDriver(),
            addCardFormView.cvvTextField.textField.rx.controlEvent(.editingDidBegin).asDriver(),
            addCardFormView.zipCodeTextField.textField.rx.controlEvent(.editingDidEnd).asDriver(),
            addCardFormView.zipCodeTextField.textField.rx.controlEvent(.editingDidBegin).asDriver(),
            viewModel.addCardFormViewModel.nicknameErrorString.map(to: ())
            )
            .drive(onNext: { [weak self] in
                self?.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += addCardFormView.expMonthTextField.getError()
        message += addCardFormView.cardNumberTextField.getError()
        message += addCardFormView.expYearTextField.getError()
        message += addCardFormView.cvvTextField.getError()
        message += addCardFormView.zipCodeTextField.getError()
        message += addCardFormView.nicknameTextField.getError()
        
        if message.isEmpty {
            saveButton.accessibilityLabel = NSLocalizedString("Save", comment: "")
        } else {
            saveButton.accessibilityLabel = String(format: NSLocalizedString("%@ Save", comment: ""), message)
        }
    }
    
    func configureCardIO() {
        CardIOUtilities.preloadCardIO() // Speeds up subsequent launch
        cardIOViewController = CardIOPaymentViewController.init(paymentDelegate: self)
        cardIOViewController.disableManualEntryButtons = true
        cardIOViewController.guideColor = .successGreen
        cardIOViewController.hideCardIOLogo = true
        cardIOViewController.collectCardholderName = false
        cardIOViewController.collectExpiry = false
        cardIOViewController.collectCVV = false
        cardIOViewController.collectPostalCode = false
        cardIOViewController.navigationBarStyle = .black
        cardIOViewController.navigationBarTintColor = .primaryColor
        cardIOViewController.navigationBar.isTranslucent = false
        cardIOViewController.navigationBar.tintColor = .white
        let titleDict: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: OpenSans.bold.of(size: 18)
        ]
        cardIOViewController.navigationBar.titleTextAttributes = titleDict
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

extension AddCreditCardViewController: CardIOPaymentViewControllerDelegate {
    func userDidCancel(_ paymentViewController: CardIOPaymentViewController!) {
        cardIOViewController.dismiss(animated: true, completion: nil)
    }
    
    func userDidProvide(_ cardInfo: CardIOCreditCardInfo!, in paymentViewController: CardIOPaymentViewController!) {
        cardIOViewController.dismiss(animated: true, completion: nil)
        addCardFormView.cardNumberTextField.textField.text = cardInfo.cardNumber
        addCardFormView.cardNumberTextField.textField.sendActions(for: .editingChanged) // updates viewModel
    }
}

extension AddCreditCardViewController: AddCardFormViewDelegate {
    func addCardFormViewDidTapCardIOButton(_ addCardFormView: AddCardFormView) {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        Analytics.log(event: .addWalletCameraOffer)
        if cameraAuthorizationStatus == .denied || cameraAuthorizationStatus == .restricted {
            let alertVC = UIAlertController(title: NSLocalizedString("Camera Access", comment: ""), message: NSLocalizedString("You must allow camera access in Settings to use this feature.", comment: ""), preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("Open Settings", comment: ""), style: .default, handler: { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }))
            present(alertVC, animated: true, completion: nil)
        } else {
            present(cardIOViewController, animated: true, completion: nil)
        }
    }
    
    func addCardFormViewDidTapCVVTooltip(_ addCardFormView: AddCardFormView) {
        let messageText: String
        switch Environment.shared.opco {
        case .bge:
            messageText = NSLocalizedString("Your security code is usually a 3 or 4 digit number found on your card.", comment: "")
        case .comEd, .peco:
            messageText = NSLocalizedString("Your security code is usually a 3 digit number found on the back of your card.", comment: "")
        }
        let infoModal = InfoModalViewController(title: NSLocalizedString("What's a CVV?", comment: ""),
                                                image: #imageLiteral(resourceName: "cvv_info"),
                                                description: messageText)
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
}
