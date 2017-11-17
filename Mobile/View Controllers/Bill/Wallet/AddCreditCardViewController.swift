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
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
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
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    func onSavePress() {
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
                    guard let `self` = self else { return }
                    self.delegate?.addCreditCardViewControllerDidAddAccount(self)
                    if self.shouldPopToRootOnSave {
                        self.navigationController?.popToRootViewController(animated: true)
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
                // Error message comes from Fiserv
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
            })
        }
        
        if shouldShowOneTouchPayWarning {
            let alertVc = UIAlertController(title: NSLocalizedString("Default Payment Account", comment: ""), message: NSLocalizedString("Are you sure you want to replace your default payment account?", comment: ""), preferredStyle: .alert)
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
            viewModel.addCardFormViewModel.nicknameErrorString.toVoid()
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
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: OpenSans.bold.of(size: 18)
        ]
        cardIOViewController.navigationBar.titleTextAttributes = titleDict
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
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        Analytics().logScreenView(AnalyticsPageView.AddWalletCameraOffer.rawValue)
        if cameraAuthorizationStatus == .denied || cameraAuthorizationStatus == .restricted {
            let alertVC = UIAlertController(title: NSLocalizedString("Camera Access", comment: ""), message: NSLocalizedString("You must allow camera access in Settings to use this feature.", comment: ""), preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("Open Settings", comment: ""), style: .default, handler: { _ in
                if let url = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.openURL(url)
                }
            }))
            present(alertVC, animated: true, completion: nil)
        } else {
            present(cardIOViewController, animated: true, completion: nil)
        }
    }
    
    func addCardFormViewDidTapCVVTooltip(_ addCardFormView: AddCardFormView) {
        let infoModal = InfoModalViewController(title: NSLocalizedString("What's a CVV?", comment: ""), image: #imageLiteral(resourceName: "cvv_info"), description: NSLocalizedString("Your security code is usually a 3 digit number found on the back of your card.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
}
