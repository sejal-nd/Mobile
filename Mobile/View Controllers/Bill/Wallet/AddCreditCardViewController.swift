//
//  AddCreditCardViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import AVFoundation

protocol AddCreditCardViewControllerDelegate: class {
    func addCreditCardViewControllerDidAddAccount(_ addCreditCardViewController: AddCreditCardViewController)
}

class AddCreditCardViewController: UIViewController {
    
    // Name on card* (BGE only) - autopopulated with user's customer name
    // Card number with camera icon*
    // Expiration month* / Expiration year*
    // CVV* / Zip*
    // Nickname (optional)
    // One touch pay
    
    let disposeBag = DisposeBag()
    
    weak var delegate: AddCreditCardViewControllerDelegate?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameOnCardTextField: FloatLabelTextField!
    @IBOutlet weak var cardNumberTextField: FloatLabelTextField!
    @IBOutlet weak var cardLogoImageView: UIImageView!
    @IBOutlet weak var expDateLabel: UILabel!
    @IBOutlet weak var expMonthTextField: FloatLabelTextField!
    @IBOutlet weak var expYearTextField: FloatLabelTextField!
    @IBOutlet weak var cvvTextField: FloatLabelTextField!
    @IBOutlet weak var cvvTooltipButton: UIButton!
    @IBOutlet weak var zipCodeTextField: FloatLabelTextField!
    @IBOutlet weak var nicknameTextField: FloatLabelTextField!
    @IBOutlet weak var oneTouchPayView: UIView!
    @IBOutlet weak var oneTouchPayDescriptionLabel: UILabel!
    @IBOutlet weak var oneTouchPaySwitch: Switch!
    @IBOutlet weak var oneTouchPayLabel: UILabel!
    @IBOutlet weak var footnoteLabel: UILabel!
    
    var cardIOViewController: CardIOPaymentViewController!
    
    let viewModel = AddCreditCardViewModel(walletService: ServiceFactory.createWalletService())
    
    let oneTouchPayService = ServiceFactory.createOneTouchPayService()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        title = NSLocalizedString("Add Card", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: #selector(onSavePress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        viewModel.saveButtonIsEnabled().bind(to: saveButton.rx.isEnabled).addDisposableTo(disposeBag)

        configureCardIO()
        
        nameOnCardTextField.textField.placeholder = NSLocalizedString("Name on Card*", comment: "")
        nameOnCardTextField.textField.delegate = self
        nameOnCardTextField.textField.returnKeyType = .next
        
        cardNumberTextField.textField.placeholder = NSLocalizedString("Card Number*", comment: "")
        cardNumberTextField.textField.delegate = self
        cardNumberTextField.textField.returnKeyType = .next
        cardNumberTextField.textField.isShowingAccessory = true
        
        expDateLabel.font = OpenSans.semibold.of(textStyle: .headline)
        expDateLabel.textColor = .blackText
        expDateLabel.text = NSLocalizedString("Expiration Date", comment: "")
    
        expMonthTextField.textField.placeholder = NSLocalizedString("MM*", comment: "")
        expMonthTextField.textField.delegate = self
        expMonthTextField.textField.keyboardType = .numberPad
        expMonthTextField.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        expYearTextField.textField.placeholder = NSLocalizedString("YYYY*", comment: "")
        expYearTextField.textField.delegate = self
        expYearTextField.textField.keyboardType = .numberPad
        expYearTextField.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        cvvTextField.textField.placeholder = NSLocalizedString("CVV*", comment: "")
        cvvTextField.textField.delegate = self
        cvvTextField.textField.keyboardType = .numberPad
        
        cvvTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        zipCodeTextField.textField.placeholder = NSLocalizedString("Zip Code*", comment: "")
        zipCodeTextField.textField.delegate = self
        zipCodeTextField.textField.keyboardType = .numberPad
        
        nicknameTextField.textField.placeholder = Environment.sharedInstance.opco == .bge ? NSLocalizedString("Nickname*", comment: "") : NSLocalizedString("Nickname (Optional)", comment: "")
        
        oneTouchPayDescriptionLabel.textColor = .blackText
        oneTouchPayDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        oneTouchPayDescriptionLabel.text = oneTouchPayService.getOneTouchPayDisplayString(forCustomerNumber: viewModel.accountDetail.customerInfo.number)
        oneTouchPayLabel.textColor = .blackText
        oneTouchPayLabel.text = NSLocalizedString("One Touch Pay", comment: "")
        
        footnoteLabel.textColor = .blackText
        footnoteLabel.font = OpenSans.regular.of(textStyle: .footnote)
        if Environment.sharedInstance.opco == .bge {
            footnoteLabel.text = NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Small business customers cannot use VISA.", comment: "")
        } else {
            footnoteLabel.text = NSLocalizedString("We accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.", comment: "")
        }
        
        if Environment.sharedInstance.opco == .bge {
            oneTouchPayView.isHidden = true // Cannot do One Touch Pay on BGE until the endpoint returns walletItemID
        } else { // BGE only fields should be removed on ComEd/PECO
            nameOnCardTextField.isHidden = true
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
        
        if Environment.sharedInstance.opco == .bge {
            let alertVc = UIAlertController(title: "Not Implemented", message: "Add credit card is not yet implemented for BGE.", preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alertVc, animated: true, completion: nil)
            return
        }
        
        let customerNumber = viewModel.accountDetail.customerInfo.number
        
        var shouldShowOneTouchPayWarning = false
        if viewModel.oneTouchPay.value {
            if oneTouchPayService.oneTouchPayItem(forCustomerNumber: customerNumber) != nil {
                shouldShowOneTouchPayWarning = true
            }
        }
        
        let addCreditCard = { (setAsOneTouchPay: Bool) in
            LoadingView.show()
            self.viewModel.addCreditCard(onSuccess: { walletItemResult in
                if setAsOneTouchPay {
                    let accountNumber = self.viewModel.cardNumber.value
                    let last4 = accountNumber.substring(from: accountNumber.index(accountNumber.endIndex, offsetBy: -4))
                    self.oneTouchPayService.setOneTouchPayItem(walletItemID: walletItemResult.walletItemId, maskedWalletItemAccountNumber: last4, paymentCategoryType: .credit, forCustomerNumber: customerNumber)
                }
                
                LoadingView.hide()
                self.delegate?.addCreditCardViewControllerDidAddAccount(self)
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
                addCreditCard(true)
            }))
            present(alertVc, animated: true, completion: nil)
        } else {
            addCreditCard(viewModel.oneTouchPay.value)
        }
        
    }
    
    func bindViewModel() {
        nameOnCardTextField.textField.rx.text.orEmpty.bind(to: viewModel.nameOnCard).addDisposableTo(disposeBag)
        cardNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.cardNumber).addDisposableTo(disposeBag)
        expMonthTextField.textField.rx.text.orEmpty.bind(to: viewModel.expMonth).addDisposableTo(disposeBag)
        expYearTextField.textField.rx.text.orEmpty.bind(to: viewModel.expYear).addDisposableTo(disposeBag)
        cvvTextField.textField.rx.text.orEmpty.bind(to: viewModel.cvv).addDisposableTo(disposeBag)
        zipCodeTextField.textField.rx.text.orEmpty.bind(to: viewModel.zipCode).addDisposableTo(disposeBag)
        nicknameTextField.textField.rx.text.orEmpty.bind(to: viewModel.nickname).addDisposableTo(disposeBag)
        oneTouchPaySwitch.rx.isOn.bind(to: viewModel.oneTouchPay).addDisposableTo(disposeBag)
    }
    
    func bindValidation() {
        viewModel.cardNumber.asObservable().subscribe(onNext: { _ in
            if let cardIcon = self.viewModel.getCardIcon() {
                self.cardLogoImageView.image = cardIcon
                self.cardNumberTextField.textField.isShowingLeftAccessory = true
            } else {
                self.cardLogoImageView.image = nil
                self.cardNumberTextField.textField.isShowingLeftAccessory = false
            }
        }).addDisposableTo(disposeBag)
        
        expMonthTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.expMonth.value.isEmpty {
                self.viewModel.expMonthIsValidMonth().single().subscribe(onNext: { valid in
                    if !valid {
                        self.expMonthTextField.setError(NSLocalizedString("Invalid Month", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
                self.viewModel.expMonthIs2Digits().single().subscribe(onNext: { valid in
                    if !valid {
                        self.expMonthTextField.setError(NSLocalizedString("Must be 2 digits", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
        }).addDisposableTo(disposeBag)
        expMonthTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.expMonthTextField.setError(nil)
        }).addDisposableTo(disposeBag)
        
        expYearTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.expYear.value.isEmpty {
                self.viewModel.expYearIsNotInPast().single().subscribe(onNext: { valid in
                    if !valid {
                        self.expYearTextField.setError(NSLocalizedString("Cannot be in the past", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
                self.viewModel.expYearIs4Digits().single().subscribe(onNext: { valid in
                    if !valid {
                        self.expYearTextField.setError(NSLocalizedString("Must be 4 digits", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
        }).addDisposableTo(disposeBag)
        expYearTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.expYearTextField.setError(nil)
        }).addDisposableTo(disposeBag)
        
        cvvTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.cvv.value.isEmpty {
                self.viewModel.cvvIsCorrectLength().single().subscribe(onNext: { valid in
                    if !valid {
                        self.cvvTextField.setError(NSLocalizedString("Must be 3 or 4 digits", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
        }).addDisposableTo(disposeBag)
        cvvTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.cvvTextField.setError(nil)
        }).addDisposableTo(disposeBag)
        
        zipCodeTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.zipCode.value.isEmpty {
                self.viewModel.zipCodeIs5Digits().single().subscribe(onNext: { valid in
                    if !valid {
                        self.zipCodeTextField.setError(NSLocalizedString("Must be 5 digits", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
        }).addDisposableTo(disposeBag)
        zipCodeTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.zipCodeTextField.setError(nil)
        }).addDisposableTo(disposeBag)
        
        viewModel.nicknameIsValid().subscribe(onNext: { valid in
            self.nicknameTextField.setError(valid ? nil : NSLocalizedString("Can only contain letters, numbers, and spaces", comment: ""))
        }).addDisposableTo(disposeBag)
    }
    
    func configureCardIO() {
        CardIOUtilities.preloadCardIO() // Speeds up subsequent launch
        cardIOViewController = CardIOPaymentViewController.init(paymentDelegate: self)
        cardIOViewController.disableManualEntryButtons = true
        cardIOViewController.guideColor = UIColor.successGreen
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
    
    @IBAction func onCardIOButtonPress() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
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
            present(cardIOViewController!, animated: true, completion: nil)
        }
    }
    
    @IBAction func onCVVTooltipPress() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("What's a CVV?", comment: ""), image: #imageLiteral(resourceName: "cvv_info"), description: NSLocalizedString("Your security code is usually a 3 digit number found on the back of your card.", comment: ""))
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

extension AddCreditCardViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let characterSet = CharacterSet(charactersIn: string)
        if textField == cardNumberTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 19
        } else if textField == expMonthTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 2
        } else if textField == expYearTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 4
        } else if textField == cvvTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 4
        } else if textField == zipCodeTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 5
        }
        return true
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        if textField == expMonthTextField.textField {
            if textField.text?.characters.count == 2 {
                expYearTextField.textField.becomeFirstResponder()
            }
        } else if textField == expYearTextField.textField {
            if textField.text?.characters.count == 4 {
                cvvTextField.textField.becomeFirstResponder()
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameOnCardTextField.textField {
            cardNumberTextField.textField.becomeFirstResponder()
        } else if textField == cardNumberTextField.textField {
            expMonthTextField.textField.becomeFirstResponder()
        }
        return false
    }

}


extension AddCreditCardViewController: CardIOPaymentViewControllerDelegate {
    func userDidCancel(_ paymentViewController: CardIOPaymentViewController!) {
        cardIOViewController.dismiss(animated: true, completion: nil)
    }
    
    func userDidProvide(_ cardInfo: CardIOCreditCardInfo!, in paymentViewController: CardIOPaymentViewController!) {
        cardIOViewController.dismiss(animated: true, completion: nil)
        cardNumberTextField.textField.text = cardInfo.cardNumber
        cardNumberTextField.textField.sendActions(for: .editingChanged) // updates viewModel
    }
}
