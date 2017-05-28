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
    
    var selectedWalletItem: WalletItem?
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var innerContentView: UIView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var bottomBarView: UIView!
    @IBOutlet weak var bottomBarShadowView: UIView!
    
    @IBOutlet weak var bankImageView: UIImageView!
    @IBOutlet weak var accountIDLabel: UILabel!
    
    @IBOutlet weak var oneTouchPayView: UIView!
    @IBOutlet weak var oneTouchPayLabel: UILabel!
    @IBOutlet weak var oneTouchPaySwitch: Switch!
    
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var convenienceFeeLabel: UILabel!
    
    @IBOutlet weak var expDateLabel: UILabel!
    @IBOutlet weak var expMonthTextField: FloatLabelTextField!
    @IBOutlet weak var expYearTextField: FloatLabelTextField!
    @IBOutlet weak var cvvTextField: FloatLabelTextField!
    @IBOutlet weak var cvvTooltipButton: UIButton!
    @IBOutlet weak var zipCodeTextField: FloatLabelTextField!

    @IBOutlet weak var deleteAccountButton: ButtonControl!
    @IBOutlet weak var deleteBankAccountLabel: UILabel!
    
    @IBOutlet weak var walletItemBGView: UIView!
    @IBOutlet weak var oneTouchPayControllerView: UIView!
    
    var isOneTouch = false
    
    var gradientLayer = CAGradientLayer()
    
    var viewModel = EditCreditCardViewModel(walletService: ServiceFactory.createWalletService())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        bindWalletItemToViewElements()
        
        buildGradientAndBackgrounds()
        
        title = NSLocalizedString("Edit Card", comment: "")
        
        buildNavigationButtons()
        
        buildCCUpdateFields()

        oneTouchPayView.isHidden = false
        
        bindViewModel()
        bindValidation()
        
        scrollView.alwaysBounceHorizontal = false
    }
    
    func buildGradientAndBackgrounds() {
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
        oneTouchPayLabel.textColor = .blackText
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
        
        deleteBankAccountLabel.font = SystemFont.regular.of(textStyle: .headline)
        deleteBankAccountLabel.textColor = UIColor(colorLiteralRed:0/255.0, green: 98/255.0, blue: 154/255.0, alpha: 1)
        
        scrollView.rx.contentOffset.asDriver()
            .map { $0.y < 0 ? UIColor.primaryColor: UIColor.white }
            .distinctUntilChanged()
            .drive(onNext: { self.scrollView.backgroundColor = $0 })
            .addDisposableTo(disposeBag)
        
        oneTouchPayLabel.textColor = .blackText
        oneTouchPayLabel.font = OpenSans.regular.of(textStyle: .footnote)
        oneTouchPayLabel.text = NSLocalizedString("Turn on One Touch Pay to easily pay from the Home screen and set this payment account as default.", comment: "")
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
        oneTouchPaySwitch.rx.isOn.bind(to: viewModel.isOneTouch).addDisposableTo(disposeBag)
        
        if let walletItem = selectedWalletItem {
            // Nickname
            let opco = Environment.sharedInstance.opco
            
            if let nickname = walletItem.nickName {
                if opco == .bge {
                    if let bankAccountType = walletItem.bankAccountType {
                        nicknameLabel.text = "\(nickname), \(bankAccountType.rawValue.uppercased())"
                    } else {
                        nicknameLabel.text = nickname.uppercased()
                    }
                } else {
                    nicknameLabel.text = nickname.uppercased()
                }
            } else {
                if opco == .bge {
                    if let bankAccountType = walletItem.bankAccountType {
                        nicknameLabel.text = bankAccountType.rawValue.uppercased()
                    }
                } else {
                    nicknameLabel.text = ""
                }
            }
            
            if let last4Digits = walletItem.maskedWalletItemAccountNumber {
                accountIDLabel.text = "**** \(last4Digits)"
            } else {
                accountIDLabel.text = ""
            }
            
            convenienceFeeLabel.text = NSLocalizedString("No Fee Applied", comment: "") // Default display
            switch opco {
            case .comEd, .peco:
                if walletItem.paymentCategoryType == .credit {
                    convenienceFeeLabel.text = NSLocalizedString("$2.35 Convenience Fee", comment: "")
                    if let paymentMethodType = walletItem.paymentMethodType {
                        switch paymentMethodType {
                        case .visa:
                            bankImageView.image = #imageLiteral(resourceName: "ic_visa")
                        case .mastercard:
                            bankImageView.image = #imageLiteral(resourceName: "ic_mastercard")
                        default:
                            bankImageView.image = #imageLiteral(resourceName: "ic_credit_placeholder")
                        }
                    }
                    
                } else if walletItem.paymentCategoryType == .check {
                    bankImageView.image = #imageLiteral(resourceName: "opco_bank")
                }
                
            case .bge:
                bankImageView.image = #imageLiteral(resourceName: "opco_bank")
                
                convenienceFeeLabel.textColor = .successGreenText
                convenienceFeeLabel.text = NSLocalizedString("Verification Status: Active", comment: "")
                
                // if credit card:
                // bottomBarLabel.text = NSLocalizedString("Fees: $1.50 Residential | 2.4% Business", comment: "")
            }
        }
        
        // TODO: Make this work
        oneTouchPayView.isHidden = !isOneTouch
    }
    
    func bindViewModel() {
        expMonthTextField.textField.rx.text.orEmpty.bind(to: viewModel.expMonth).addDisposableTo(disposeBag)
        expYearTextField.textField.rx.text.orEmpty.bind(to: viewModel.expYear).addDisposableTo(disposeBag)
        cvvTextField.textField.rx.text.orEmpty.bind(to: viewModel.cvv).addDisposableTo(disposeBag)
        zipCodeTextField.textField.rx.text.orEmpty.bind(to: viewModel.zipCode).addDisposableTo(disposeBag)
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

    
    @IBAction func toggleOneTouch(_ sender: Any) {
        isOneTouch = !isOneTouch
        
        oneTouchPayView.isHidden = !isOneTouch
        
        // update preferences
    }
    
    @IBAction func onDeletePress(_ sender: Any) {
        deleteCreditCard()
    }
    
    ///
    func onCancelPress() {
        // We do this to cover the case where we push ForgotUsernameViewController from ForgotPasswordViewController.
        // When that happens, we want the cancel action to go straight back to LoginViewController.
        for vc in (navigationController?.viewControllers)! {
            guard let walletVC = vc as? WalletViewController else {
                continue
            }
            
            navigationController?.popToViewController(walletVC, animated: true)
            
            break
        }
    }
    
    func onSavePress() {
        view.endEditing(true)
        
        LoadingView.show()
        
        viewModel.editCreditCard(onSuccess: {
            LoadingView.hide()
            self.delegate?.editCreditCardViewControllerDidEditAccount(self, message: "Changes saved")
            
            _ = self.navigationController?.popViewController(animated: true)
        }, onError: { errMessage in
            LoadingView.hide()
            
            print(errMessage)
        })
    }

    
    ///
    func deleteCreditCard() {
        var messageString = NSLocalizedString("Are you sure you want to delete this card?", comment: "")
        
//        if Environment.sharedInstance.opco == .bge {
//            messageString = NSLocalizedString("Deleting this payment account will also delete all the pending payments associated with this payment account. Please click 'Delete' to delete this payment account.", comment: "")
//        }
        
        let alertController = UIAlertController(title: NSLocalizedString("Delete Bank Account", comment: ""), message: messageString, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .default, handler: { _ in
            LoadingView.show()
            
            self.viewModel.editCreditCard(onSuccess: {
                LoadingView.hide()
                self.delegate?.editCreditCardViewControllerDidEditAccount(self, message: "Credit Card deleted")
                
                _ = self.navigationController?.popViewController(animated: true)
            }, onError: { errMessage in
                LoadingView.hide()
                
                print(errMessage)
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
    
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        if textField == nameOnCardTextField.textField {
//            cardNumberTextField.textField.becomeFirstResponder()
//        } else if textField == cardNumberTextField.textField {
//            expMonthTextField.textField.becomeFirstResponder()
//        }
//        return false
//    }
    
}

