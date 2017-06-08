//
//  EditCreditCardViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/27/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol EditCreditCardViewControllerDelegate: class {
    func editCreditCardViewControllerDidEditAccount(_ editCreditCardViewController: EditCreditCardViewController, message: String)
}

class EditCreditCardViewController: UIViewController {

    let disposeBag = DisposeBag()
    
    weak var delegate: EditCreditCardViewControllerDelegate?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var innerContentView: UIView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var bottomBarView: UIView!
    @IBOutlet weak var bottomBarShadowView: UIView!
    
    @IBOutlet weak var bankImageView: UIImageView!
    @IBOutlet weak var accountIDLabel: UILabel!
    @IBOutlet weak var oneTouchPayCardView: UIView!
    @IBOutlet weak var oneTouchPayCardLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var convenienceFeeLabel: UILabel!
    
    @IBOutlet weak var expDateLabel: UILabel!
    @IBOutlet weak var expMonthTextField: FloatLabelTextField!
    @IBOutlet weak var expYearTextField: FloatLabelTextField!
    @IBOutlet weak var cvvTextField: FloatLabelTextField!
    @IBOutlet weak var cvvTooltipButton: UIButton!
    @IBOutlet weak var zipCodeTextField: FloatLabelTextField!
    @IBOutlet weak var oneTouchPayDescriptionLabel: UILabel!
    @IBOutlet weak var oneTouchPaySwitch: Switch!
    @IBOutlet weak var oneTouchPayLabel: UILabel!

    @IBOutlet weak var deleteCardLabel: UILabel!
    
    @IBOutlet weak var walletItemBGView: UIView!
    
    var gradientLayer = CAGradientLayer()
    
    var viewModel = EditCreditCardViewModel(walletService: ServiceFactory.createWalletService())
    
    let oneTouchPayService = ServiceFactory.createOneTouchPayService()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        // Put white background on stack view
        let bg = UIView(frame: stackView.bounds)
        bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bg.backgroundColor = .white
        stackView.addSubview(bg)
        stackView.sendSubview(toBack: bg)
        
        bindWalletItemToViewElements()
        
        buildGradientAndBackgrounds()
        
        title = NSLocalizedString("Edit Card", comment: "")
        
        buildNavigationButtons()
        
        buildCCUpdateFields()
        
        bindViewModel()
        bindValidation()
        
        scrollView.alwaysBounceHorizontal = false
    }
    
    func buildGradientAndBackgrounds() {
        scrollView.rx.contentOffset.asDriver()
            .map { $0.y < 0 ? UIColor.primaryColor: UIColor.white }
            .distinctUntilChanged()
            .drive(onNext: { self.scrollView.backgroundColor = $0 })
            .addDisposableTo(disposeBag)
        
        walletItemBGView.backgroundColor = .primaryColor
        
        innerContentView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        innerContentView.layer.cornerRadius = 15
        
        gradientView.layer.cornerRadius = 15
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(red: 238/255, green: 242/255, blue: 248/255, alpha: 1).cgColor
        ]
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        
        accountIDLabel.textColor = .blackText
        oneTouchPayCardLabel.textColor = .blackText
        oneTouchPayCardLabel.text = NSLocalizedString("One Touch Pay", comment: "")
        nicknameLabel.textColor = .blackText
        
        bottomBarShadowView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        bottomBarView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        convenienceFeeLabel.textColor = .blackText
    }
    
    func buildNavigationButtons() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: #selector(onSavePress))

        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        
        viewModel.saveButtonIsEnabled().bind(to: saveButton.rx.isEnabled).addDisposableTo(disposeBag)
    }
    
    func buildCCUpdateFields() {
        expDateLabel.font = OpenSans.semibold.of(textStyle: .headline)
        expDateLabel.textColor = .blackText
        expDateLabel.text = NSLocalizedString("Expiration Date", comment: "")
        
        expMonthTextField.textField.placeholder = NSLocalizedString("MM", comment: "")
        expMonthTextField.textField.delegate = self
        expMonthTextField.textField.keyboardType = .numberPad
        expMonthTextField.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        expYearTextField.textField.placeholder = NSLocalizedString("YYYY", comment: "")
        expYearTextField.textField.delegate = self
        expYearTextField.textField.keyboardType = .numberPad
        expYearTextField.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        cvvTextField.textField.placeholder = NSLocalizedString("CVV", comment: "")
        cvvTextField.textField.delegate = self
        cvvTextField.textField.keyboardType = .numberPad
        
        cvvTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        zipCodeTextField.textField.placeholder = NSLocalizedString("Zip Code", comment: "")
        zipCodeTextField.textField.delegate = self
        zipCodeTextField.textField.keyboardType = .numberPad
        
        deleteCardLabel.font = SystemFont.regular.of(textStyle: .headline)
        deleteCardLabel.textColor = .actionBlue
        
        oneTouchPayDescriptionLabel.textColor = .blackText
        oneTouchPayDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        oneTouchPayDescriptionLabel.text = oneTouchPayService.getOneTouchPayDisplayString(forCustomerNumber: viewModel.accountDetail.customerInfo.number)
        oneTouchPayLabel.textColor = .blackText
        oneTouchPayLabel.text = NSLocalizedString("One Touch Pay", comment: "")
        
        if Environment.sharedInstance.opco == .bge { // Remove exp date, etc., if BGE for this version. Added w V2.
            expDateLabel.isHidden = true
            expMonthTextField.isHidden = true
            expYearTextField.isHidden = true
            cvvTooltipButton.isHidden = true
            zipCodeTextField.isHidden = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        innerContentView.layoutIfNeeded()
        
        // Round only the top corners
        gradientLayer.frame = gradientView.frame
        
        let gradientPath = UIBezierPath(roundedRect:gradientLayer.bounds,
                                        byRoundingCorners:[.topLeft, .topRight],
                                        cornerRadii: CGSize(width: 15, height:  15))
        let gradientMaskLayer = CAShapeLayer()
        gradientMaskLayer.path = gradientPath.cgPath
        gradientLayer.mask = gradientMaskLayer
        
        // Round only the bottom corners
        let bottomBarPath = UIBezierPath(roundedRect:bottomBarView.bounds,
                                         byRoundingCorners:[.bottomLeft, .bottomRight],
                                         cornerRadii: CGSize(width: 15, height:  15))
        let bottomBarMaskLayer = CAShapeLayer()
        bottomBarMaskLayer.path = bottomBarPath.cgPath
        bottomBarView.layer.mask = bottomBarMaskLayer
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /////////////////////////////////////////////////////////////////////////////////////////////////
    func bindWalletItemToViewElements() {
        
        let opco = Environment.sharedInstance.opco
        
        let walletItem = viewModel.walletItem!
        
        nicknameLabel.text = walletItem.nickName != nil ? walletItem.nickName!.uppercased() : ""
        
        if let last4Digits = walletItem.maskedWalletItemAccountNumber {
            accountIDLabel.text = "**** \(last4Digits)"
        } else {
            accountIDLabel.text = ""
        }
        
        convenienceFeeLabel.text = NSLocalizedString("No Fee Applied", comment: "") // Default display
        convenienceFeeLabel.textColor = .blackText
        switch opco {
        case .comEd, .peco:
            convenienceFeeLabel.text = NSLocalizedString("$2.35 Convenience Fee", comment: "")
            if let paymentMethodType = walletItem.paymentMethodType {
                switch paymentMethodType {
                case .visa:
                    bankImageView.image = #imageLiteral(resourceName: "ic_visa")
                    bankImageView.accessibilityLabel = NSLocalizedString("Visa card", comment: "")
                case .mastercard:
                    bankImageView.image = #imageLiteral(resourceName: "ic_mastercard")
                    bankImageView.accessibilityLabel = NSLocalizedString("Master card", comment: "")
                case .discover:
                    bankImageView.image = #imageLiteral(resourceName: "ic_discover")
                    bankImageView.accessibilityLabel = NSLocalizedString("Discover card", comment: "")
                case .americanexpress:
                    bankImageView.image = #imageLiteral(resourceName: "ic_amex")
                    bankImageView.accessibilityLabel = NSLocalizedString("American Express card", comment: "")
                }
            } else {
                bankImageView.image = #imageLiteral(resourceName: "ic_credit_placeholder")
                bankImageView.accessibilityLabel = NSLocalizedString("Credit card", comment: "")
            }
        case .bge:
            bankImageView.image = #imageLiteral(resourceName: "ic_credit_placeholder")
        }
        

    }
    
    func bindViewModel() {
        expMonthTextField.textField.rx.text.orEmpty.bind(to: viewModel.expMonth).addDisposableTo(disposeBag)
        expYearTextField.textField.rx.text.orEmpty.bind(to: viewModel.expYear).addDisposableTo(disposeBag)
        cvvTextField.textField.rx.text.orEmpty.bind(to: viewModel.cvv).addDisposableTo(disposeBag)
        zipCodeTextField.textField.rx.text.orEmpty.bind(to: viewModel.zipCode).addDisposableTo(disposeBag)

        oneTouchPaySwitch.rx.isOn.bind(to: viewModel.oneTouchPay).addDisposableTo(disposeBag)
        
        oneTouchPayCardView.isHidden = true
        let oneTouchPayWalletItem = oneTouchPayService.oneTouchPayItem(forCustomerNumber: viewModel.accountDetail.customerInfo.number)
        if (oneTouchPayWalletItem == viewModel.walletItem) {
            oneTouchPayCardView.isHidden = false
            viewModel.oneTouchPayInitialValue.value = true
            oneTouchPaySwitch.isOn = true
            oneTouchPaySwitch.sendActions(for: .valueChanged)
        }
    }
    
    func bindValidation() {
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
    
    // MARK: - Actions

    
    @IBAction func onCVVTooltipPress() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("What's a CVV?", comment: ""), image: #imageLiteral(resourceName: "cvv_info"), description: NSLocalizedString("Your security code is usually a 3 digit number found on the back of your card.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
    }

    
    @IBAction func onDeletePress(_ sender: Any) {
        deleteCreditCard()
    }
    
    ///
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    func onSavePress() {
        view.endEditing(true)
        
        let customerNumber = viewModel.accountDetail.customerInfo.number
        
        viewModel.webServicesDataChanged().single().subscribe(onNext: { changed in
            if changed {
                var shouldShowOneTouchPayWarning = false
                if self.viewModel.oneTouchPay.value {
                    let otpItem = self.oneTouchPayService.oneTouchPayItem(forCustomerNumber: customerNumber)
                    if otpItem != nil && otpItem != self.viewModel.walletItem {
                        shouldShowOneTouchPayWarning = true
                    }
                }
                
                let editCreditCard = { (oneTouchPay: Bool) in
                    
                    let editOneTouchPay = {
                        if oneTouchPay {
                            self.oneTouchPayService.setOneTouchPayItem(walletItemID: self.viewModel.walletItem.walletItemID!, maskedWalletItemAccountNumber: self.viewModel.walletItem.maskedWalletItemAccountNumber!, paymentCategoryType: .credit, forCustomerNumber: customerNumber)
                        } else {
                            self.oneTouchPayService.deleteTouchPayItem(forCustomerNumber: customerNumber)
                        }
                    }
                    
                    
                    if Environment.sharedInstance.opco == .bge {
                        editOneTouchPay()
                        self.delegate?.editCreditCardViewControllerDidEditAccount(self, message: NSLocalizedString("Changes saved", comment: ""))
                        _ = self.navigationController?.popViewController(animated: true)
                    } else {
                        LoadingView.show()
                        self.viewModel.editCreditCard(onSuccess: {
                            editOneTouchPay()
                            
                            LoadingView.hide()
                            self.delegate?.editCreditCardViewControllerDidEditAccount(self, message: NSLocalizedString("Changes saved", comment: ""))
                            _ = self.navigationController?.popViewController(animated: true)
                        }, onError: { errMessage in
                            LoadingView.hide()
                            let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                            self.present(alertVc, animated: true, completion: nil)
                        })
                    }
                    
                }
                
                if shouldShowOneTouchPayWarning {
                    let alertVc = UIAlertController(title: NSLocalizedString("One Touch Pay", comment: ""), message: NSLocalizedString("Are you sure you want to replace your current One Touch Pay payment account?", comment: ""), preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { _ in
                        editCreditCard(true)
                    }))
                    self.present(alertVc, animated: true, completion: nil)
                } else {
                    editCreditCard(self.viewModel.oneTouchPay.value)
                }
            } else {
                
                let toggleOneTouchPay = {
                    if self.viewModel.oneTouchPay.value {
                        self.oneTouchPayService.setOneTouchPayItem(walletItemID: self.viewModel.walletItem.walletItemID!, maskedWalletItemAccountNumber: self.viewModel.walletItem.maskedWalletItemAccountNumber!, paymentCategoryType: .credit, forCustomerNumber: customerNumber)
                        self.delegate?.editCreditCardViewControllerDidEditAccount(self, message: NSLocalizedString("Changes saved", comment: ""))
                        _ = self.navigationController?.popViewController(animated: true)
                    } else {
                        self.oneTouchPayService.deleteTouchPayItem(forCustomerNumber: customerNumber)
                        self.delegate?.editCreditCardViewControllerDidEditAccount(self, message: NSLocalizedString("Changes saved", comment: ""))
                        _ = self.navigationController?.popViewController(animated: true)
                    }
                }
                if self.viewModel.oneTouchPay.value {
                    if self.oneTouchPayService.oneTouchPayItem(forCustomerNumber: customerNumber) != nil {
                        let alertVc = UIAlertController(title: NSLocalizedString("One Touch Pay", comment: ""), message: NSLocalizedString("Are you sure you want to replace your current One Touch Pay payment account?", comment: ""), preferredStyle: .alert)
                        alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                        alertVc.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { _ in
                            toggleOneTouchPay()
                        }))
                        self.present(alertVc, animated: true, completion: nil)
                    } else {
                        toggleOneTouchPay()
                    }
                } else {
                    toggleOneTouchPay()
                }
            }
        }).addDisposableTo(disposeBag)
    }

    
    ///
    func deleteCreditCard() {
        let alertController = UIAlertController(title: NSLocalizedString("Delete Card", comment: ""), message: NSLocalizedString("Are you sure you want to delete this card?", comment: ""), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { _ in
            LoadingView.show()
            self.viewModel.deleteCreditCard(onSuccess: {
                let customerNumber = self.viewModel.accountDetail.customerInfo.number
                if self.oneTouchPayService.oneTouchPayItem(forCustomerNumber: customerNumber) == self.viewModel.walletItem {
                    self.oneTouchPayService.deleteTouchPayItem(forCustomerNumber: customerNumber)
                }
                LoadingView.hide()
                self.delegate?.editCreditCardViewControllerDidEditAccount(self, message: NSLocalizedString("Card deleted", comment: ""))
                _ = self.navigationController?.popViewController(animated: true)
            }, onError: { errMessage in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alertVc, animated: true, completion: nil)
            })
        }))
        
        present(alertController, animated: true, completion: nil)
    }
}

extension EditCreditCardViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let characterSet = CharacterSet(charactersIn: string)

        if textField == expMonthTextField.textField {
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
    
}

