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
    @IBOutlet weak var innerContentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var innerContentViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var gradientView: UIView!
    
    @IBOutlet weak var creditImageView: UIImageView!
    @IBOutlet weak var accountIDLabel: UILabel!
    @IBOutlet weak var oneTouchPayCardView: UIView!
    @IBOutlet weak var oneTouchPayCardLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var expiredView: UIView!
    @IBOutlet weak var expiredLabel: UILabel!
    
    @IBOutlet weak var expDateLabel: UILabel!
    @IBOutlet weak var expMonthTextField: FloatLabelTextField!
    @IBOutlet weak var expYearTextField: FloatLabelTextField!
    @IBOutlet weak var cvvTextField: FloatLabelTextField!
    @IBOutlet weak var cvvTooltipButton: UIButton!
    @IBOutlet weak var zipCodeTextField: FloatLabelTextField!
    @IBOutlet weak var oneTouchPayDescriptionLabel: UILabel!
    @IBOutlet weak var oneTouchPaySwitch: Switch!
    @IBOutlet weak var oneTouchPayLabel: UILabel!

    @IBOutlet weak var deleteCardButton: ButtonControl!
    @IBOutlet weak var deleteCardLabel: UILabel!
    
    @IBOutlet weak var walletItemBGView: UIView!
    
    var gradientLayer = CAGradientLayer()
    
    var viewModel = EditCreditCardViewModel(walletService: ServiceFactory.createWalletService())
    var saveButton = UIBarButtonItem()
    
    var shouldPopToRootOnSave = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Put white background on stack view
        let bg = UIView(frame: stackView.bounds)
        bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bg.backgroundColor = .white
        stackView.addSubview(bg)
        stackView.sendSubviewToBack(bg)
        
        bindWalletItemToViewElements()
        
        buildGradientAndBackgrounds()
        
        title = NSLocalizedString("Edit Card", comment: "")
        
        buildNavigationButtons()
        
        buildCCUpdateFields()
        
        bindViewModel()
        bindValidation()
        
        scrollView.alwaysBounceHorizontal = false
        
        if let ad = UIApplication.shared.delegate as? AppDelegate, let window = ad.window {
            if window.bounds.width < 375 { // If smaller than iPhone 6 width
                innerContentViewLeadingConstraint.constant = 15
                innerContentViewTrailingConstraint.constant = 15
            }
        }
    }
    
    func buildGradientAndBackgrounds() {
        scrollView.rx.contentOffset.asDriver()
            .map { $0.y < 0 ? UIColor.primaryColor: UIColor.white }
            .distinctUntilChanged()
            .drive(scrollView.rx.backgroundColor)
            .disposed(by: disposeBag)
        
        walletItemBGView.backgroundColor = StormModeStatus.shared.isOn ? .stormModeBlack : .primaryColor
        
        innerContentView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        innerContentView.layer.cornerRadius = 15
        innerContentView.layer.masksToBounds = true
        
        gradientView.layer.cornerRadius = 15
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(red: 238/255, green: 242/255, blue: 248/255, alpha: 1).cgColor
        ]
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        
        accountIDLabel.textColor = .blackText
        accountIDLabel.font = OpenSans.regular.of(textStyle: .title1)
        oneTouchPayCardLabel.font = SystemFont.regular.of(textStyle: .footnote)

        oneTouchPayCardLabel.textColor = .blackText
        oneTouchPayCardLabel.text = NSLocalizedString("Default", comment: "")
        nicknameLabel.textColor = .blackText
        nicknameLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        oneTouchPayLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        expiredView.layer.borderWidth = 2
        expiredView.layer.borderColor = UIColor.errorRed.cgColor
        expiredLabel.textColor = .errorRed
    }
    
    func buildNavigationButtons() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: nil)

        saveButton.rx.tap.asDriver()
            .withLatestFrom(viewModel.cardDataEntered)
            .drive(onNext: { [weak self] cardDataEntered in
                self?.onSavePress(cardDataEntered: cardDataEntered)
            })
            .disposed(by: disposeBag)
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        
        viewModel.saveButtonIsEnabled.drive(saveButton.rx.isEnabled).disposed(by: disposeBag)
    }
    
    func buildCCUpdateFields() {
        expDateLabel.font = OpenSans.semibold.of(textStyle: .headline)
        expDateLabel.textColor = .blackText
        expDateLabel.text = NSLocalizedString("Expiration Date", comment: "")
        
        expMonthTextField.textField.placeholder = NSLocalizedString("MM*", comment: "")
        expMonthTextField.textField.customAccessibilityLabel = NSLocalizedString("Month, two digits", comment: "")
        expMonthTextField.textField.delegate = self
        expMonthTextField.setKeyboardType(.numberPad)
        expMonthTextField.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        expYearTextField.textField.placeholder = NSLocalizedString("YYYY*", comment: "")
        expYearTextField.textField.customAccessibilityLabel = NSLocalizedString("Year, four digits", comment: "")
        expYearTextField.textField.delegate = self
        expYearTextField.setKeyboardType(.numberPad)
        expYearTextField.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        cvvTextField.textField.placeholder = NSLocalizedString("CVV*", comment: "")
        cvvTextField.textField.delegate = self
        cvvTextField.setKeyboardType(.numberPad)
        
        cvvTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        zipCodeTextField.textField.placeholder = NSLocalizedString("Zip Code*", comment: "")
        zipCodeTextField.textField.delegate = self
        zipCodeTextField.setKeyboardType(.numberPad)
        
        deleteCardButton.accessibilityLabel = NSLocalizedString("Delete card", comment: "")
        deleteCardLabel.font = SystemFont.regular.of(textStyle: .headline)
        deleteCardLabel.textColor = .actionBlue
        
        oneTouchPayDescriptionLabel.textColor = .blackText
        oneTouchPayDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        oneTouchPayDescriptionLabel.text = viewModel.oneTouchDisplayString
        oneTouchPayLabel.textColor = .blackText
        oneTouchPayLabel.text = NSLocalizedString("Default Payment Method", comment: "")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        innerContentView.layoutIfNeeded()
        gradientLayer.frame = gradientView.frame
    }
    
    func bindWalletItemToViewElements() {
        let walletItem = viewModel.walletItem!
        
        if let nickname = walletItem.nickName {
            nicknameLabel.text = nickname.uppercased()
        } else {
            nicknameLabel.text = ""
        }
        
        if let last4Digits = walletItem.maskedWalletItemAccountNumber {
            if viewModel.walletItem.isExpired { // Need smaller width
                accountIDLabel.text = "...\(last4Digits)"
            } else {
                accountIDLabel.text = "**** \(last4Digits)"
            }
            accountIDLabel.accessibilityLabel = String(format: NSLocalizedString(", Account number ending in %@", comment: ""), last4Digits)
        } else {
            accountIDLabel.text = ""
        }
        
        if !viewModel.walletItem.isExpired {
            expiredLabel.text = ""
            expiredView.isHidden = true
        }
        
        creditImageView.image = #imageLiteral(resourceName: "opco_credit_card")
        creditImageView.isAccessibilityElement = true
        creditImageView.accessibilityLabel = NSLocalizedString("Credit card", comment: "")
    }
    
    func bindViewModel() {
        expMonthTextField.textField.rx.text.orEmpty.bind(to: viewModel.expMonth).disposed(by: disposeBag)
        expYearTextField.textField.rx.text.orEmpty.bind(to: viewModel.expYear).disposed(by: disposeBag)
        cvvTextField.textField.rx.text.orEmpty.bind(to: viewModel.cvv).disposed(by: disposeBag)
        zipCodeTextField.textField.rx.text.orEmpty.bind(to: viewModel.zipCode).disposed(by: disposeBag)

        oneTouchPaySwitch.rx.isOn.bind(to: viewModel.oneTouchPay).disposed(by: disposeBag)
        
        oneTouchPayCardView.isHidden = true
        let oneTouchPayWalletItem = viewModel.oneTouchPayItem
        if (oneTouchPayWalletItem == viewModel.walletItem) {
            oneTouchPayCardView.isHidden = false
            viewModel.oneTouchPayInitialValue.value = true
            oneTouchPaySwitch.isOn = true
            oneTouchPaySwitch.sendActions(for: .valueChanged)
        }
    }
    
    func bindValidation() {
        expMonthTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.expMonth.asDriver(), viewModel.expMonthIsValidMonth, viewModel.expMonthIs2Digits))
            .drive(onNext: { [weak self] expMonth, expMonthIsValidMonth, expMonthIs2Digits in
                if !expMonth.isEmpty {
                    if !expMonthIsValidMonth {
                        self?.expMonthTextField.setError(NSLocalizedString("Invalid Month", comment: ""))
                    } else if !expMonthIs2Digits {
                        self?.expMonthTextField.setError(NSLocalizedString("Must be 2 digits", comment: ""))
                    }
                }
                self?.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        
        expMonthTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.expMonthTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        expYearTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.expYear.asDriver(), viewModel.expYearIsNotInPast, viewModel.expYearIs4Digits))
            .drive(onNext: { [weak self] expYear, expYearIsNotInPast, expYearIs4Digits in
                if !expYear.isEmpty {
                    if !expYearIsNotInPast {
                        self?.expYearTextField.setError(NSLocalizedString("Cannot be in the past", comment: ""))
                    } else if !expYearIs4Digits {
                        self?.expYearTextField.setError(NSLocalizedString("Must be 4 digits", comment: ""))
                    }
                }
                self?.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        
        expYearTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.expYearTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        cvvTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.cvv.asDriver(), viewModel.cvvIsCorrectLength))
            .drive(onNext: { [weak self] cvv, cvvIsCorrectLength in
                if !cvv.isEmpty && !cvvIsCorrectLength {
                    self?.expYearTextField.setError(NSLocalizedString("Cannot be in the past", comment: ""))
                }
                self?.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        
        cvvTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.cvvTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        zipCodeTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.zipCode.asDriver(), viewModel.zipCodeIs5Digits))
            .drive(onNext: { [weak self] zipCode, zipCodeIs5Digits in
                if !zipCode.isEmpty && !zipCodeIs5Digits {
                    self?.zipCodeTextField.setError(NSLocalizedString("Must be 5 digits", comment: ""))
                }
                self?.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        
        zipCodeTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.zipCodeTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += expMonthTextField.getError()
        message += expYearTextField.getError()
        message += cvvTextField.getError()
        message += zipCodeTextField.getError()
        
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
    
    // MARK: - Actions

    
    @IBAction func onCVVTooltipPress() {
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

    
    @IBAction func onDeletePress(_ sender: Any) {
        deleteCreditCard()
    }
    
    ///
    @objc func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    func onSavePress(cardDataEntered: Bool) {
        view.endEditing(true)
        
        var shouldShowOneTouchPayReplaceWarning = false
        var shouldShowOneTouchPayDisableWarning = false
        let otpItem = viewModel.oneTouchPayItem
        if viewModel.oneTouchPay.value {
            if otpItem != nil && otpItem != viewModel.walletItem {
                shouldShowOneTouchPayReplaceWarning = true
            }
        } else {
            if otpItem == viewModel.walletItem {
                shouldShowOneTouchPayDisableWarning = true
            }
        }
        
        let handleSuccess = { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }
            self.delegate?.editCreditCardViewControllerDidEditAccount(self, message: NSLocalizedString("Changes saved", comment: ""))
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
        
        if cardDataEntered {
            let editCreditCard = { [weak self] (oneTouchPay: Bool) in
                let editOneTouchPay = { [weak self] in
                    guard let self = self else { return }
                    if oneTouchPay {
                        self.viewModel.enableOneTouchPay(onSuccess: {
                            handleSuccess()
                        }, onError: { (error: String) in
                            //In this case, the card was successfully updated, there is no visual
                            //feedback otherwise that the fields updated successfully so this is the lesser evil.
                            handleSuccess()
                        })
                    } else {
                        self.viewModel.deleteOneTouchPay(onSuccess: {
                            handleSuccess()
                        }, onError: { (error: String) in
                            //In this case, the card was successfully updated, there is no visual
                            //feedback otherwise that the fields updated successfully so this is the lesser evil.
                            handleSuccess()
                        })
                    }
                }
                
                LoadingView.show()
                self?.viewModel.editCreditCard(onSuccess: {
                    editOneTouchPay()
                }, onError: { [weak self] errMessage in
                    LoadingView.hide()
                    let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self?.present(alertVc, animated: true, completion: nil)
                })
            }
            
            if shouldShowOneTouchPayReplaceWarning {
                let alertVc = UIAlertController(title: NSLocalizedString("Default Payment Method", comment: ""), message: NSLocalizedString("Are you sure you want to replace your default payment method?", comment: ""), preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { _ in
                    editCreditCard(true)
                }))
                present(alertVc, animated: true, completion: nil)
            } else if shouldShowOneTouchPayDisableWarning {
                let alertVc = UIAlertController(title: NSLocalizedString("Default Payment Method", comment: ""), message: NSLocalizedString("Are you sure you want to turn off your default payment method? You will no longer be able to pay from the Home screen.", comment: ""), preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Turn Off", comment: ""), style: .default, handler: { _ in
                    editCreditCard(false)
                }))
                present(alertVc, animated: true, completion: nil)
            } else {
                editCreditCard(viewModel.oneTouchPay.value)
            }
        } else {
            let toggleOneTouchPay = { [weak self] in
                LoadingView.show()
                guard let self = self else { return }
                if self.viewModel.oneTouchPay.value {
                    self.viewModel.enableOneTouchPay(onSuccess: {
                        handleSuccess()
                    }, onError: { [weak self] (errMessage: String) in
                        LoadingView.hide()
                        let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                        alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                        self?.present(alertVc, animated: true, completion: nil)
                    })
                } else {
                    self.viewModel.deleteOneTouchPay(onSuccess: {
                        handleSuccess()
                    }, onError: { [weak self] (errMessage: String) in
                        let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                        alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                        self?.present(alertVc, animated: true, completion: nil)
                    })
                }
            }
            
            if shouldShowOneTouchPayReplaceWarning {
                let alertVc = UIAlertController(title: NSLocalizedString("Default Payment Method", comment: ""), message: NSLocalizedString("Are you sure you want to replace your default payment method?", comment: ""), preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { _ in
                    toggleOneTouchPay()
                }))
                present(alertVc, animated: true, completion: nil)
            } else if shouldShowOneTouchPayDisableWarning {
                let alertVc = UIAlertController(title: NSLocalizedString("Default Payment Method", comment: ""), message: NSLocalizedString("Are you sure you want to turn off your default payment method? You will no longer be able to pay from the Home screen.", comment: ""), preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Turn Off", comment: ""), style: .default, handler: { _ in
                    toggleOneTouchPay()
                }))
                present(alertVc, animated: true, completion: nil)
            } else {
                toggleOneTouchPay()
            }
        }
    }

    
    ///
    func deleteCreditCard() {
        let alertController = UIAlertController(title: NSLocalizedString("Delete Card", comment: ""), message: NSLocalizedString("Are you sure you want to delete this card?", comment: ""), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { [weak self] _ in
            LoadingView.show()
            self?.viewModel.deleteCreditCard(onSuccess: { [weak self] in
                LoadingView.hide()
                guard let self = self else { return }
                self.delegate?.editCreditCardViewControllerDidEditAccount(self, message: NSLocalizedString("Card deleted", comment: ""))
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
            }, onError: { [weak self] errMessage in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
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
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 2
        } else if textField == expYearTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 4
        } else if textField == cvvTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 4
        } else if textField == zipCodeTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 5
        }
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField == expMonthTextField.textField {
            if textField.text?.count == 2 {
                expYearTextField.textField.becomeFirstResponder()
            }
        } else if textField == expYearTextField.textField {
            if textField.text?.count == 4 {
                cvvTextField.textField.becomeFirstResponder()
            }
        }
    }
    
}

