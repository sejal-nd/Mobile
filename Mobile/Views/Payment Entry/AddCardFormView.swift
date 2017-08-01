//
//  AddCardFormView.swift
//  Mobile
//
//  Created by Marc Shilling on 7/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol AddCardFormViewDelegate: class {
    func addCardFormViewDidTapCardIOButton(_ addCardFormView: AddCardFormView)
    func addCardFormViewDidTapCVVTooltip(_ addCardFormView: AddCardFormView)
}

class AddCardFormView: UIView {
    
    weak var delegate: AddCardFormViewDelegate?
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var nameOnCardTextField: FloatLabelTextField!
    @IBOutlet weak var cardNumberTextField: FloatLabelTextField!
    @IBOutlet weak var cardIOButton: UIButton!
    @IBOutlet weak var cardLogoImageView: UIImageView!
    
    @IBOutlet weak var expDateView: UIView!
    @IBOutlet weak var expDateLabel: UILabel!
    @IBOutlet weak var expMonthTextField: FloatLabelTextField!
    @IBOutlet weak var expYearTextField: FloatLabelTextField!
    
    @IBOutlet weak var cvvZipView: UIView!
    @IBOutlet weak var cvvTextField: FloatLabelTextField!
    @IBOutlet weak var cvvTooltipButton: UIButton!
    @IBOutlet weak var zipCodeTextField: FloatLabelTextField!
    
    @IBOutlet weak var saveToWalletStackView: UIStackView!
    @IBOutlet weak var saveToWalletSwitch: Switch!
    @IBOutlet weak var saveToWalletLabel: UILabel!
    @IBOutlet weak var byNotSavingLabel: UILabel!
    
    @IBOutlet weak var nicknameTextField: FloatLabelTextField!
    
    @IBOutlet weak var oneTouchPayView: UIView!
    @IBOutlet weak var oneTouchPayDescriptionLabel: UILabel!
    @IBOutlet weak var oneTouchPaySwitch: Switch!
    @IBOutlet weak var oneTouchPayLabel: UILabel!
    
    @IBOutlet weak var footnoteLabel: UILabel!
    
    var viewModel = AddCardFormViewModel(walletService: ServiceFactory.createWalletService())

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(AddCardFormView.className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
        
        nameOnCardTextField.textField.placeholder = NSLocalizedString("Name on Card*", comment: "")
        nameOnCardTextField.textField.delegate = self
        nameOnCardTextField.textField.returnKeyType = .next
        
        cardNumberTextField.textField.placeholder = NSLocalizedString("Card Number*", comment: "")
        cardNumberTextField.textField.delegate = self
        cardNumberTextField.textField.returnKeyType = .next
        cardNumberTextField.textField.isShowingAccessory = true
        cardIOButton.accessibilityLabel = NSLocalizedString("Take a photo to scan credit card number", comment: "")
        
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
        
        saveToWalletLabel.textColor = .deepGray
        saveToWalletLabel.text = NSLocalizedString("Save to My Wallet", comment: "")
        byNotSavingLabel.textColor = .blackText
        byNotSavingLabel.font = OpenSans.regular.of(textStyle: .footnote)
        byNotSavingLabel.text = NSLocalizedString("By not saving this payment account, you will only be eligible to make an instant payment.", comment: "")
        
        nicknameTextField.textField.placeholder = Environment.sharedInstance.opco == .bge ? NSLocalizedString("Nickname*", comment: "") : NSLocalizedString("Nickname (Optional)", comment: "")
        
        oneTouchPayDescriptionLabel.textColor = .blackText
        oneTouchPayDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        oneTouchPayLabel.textColor = .blackText
        oneTouchPayLabel.text = NSLocalizedString("One Touch Pay", comment: "")
        
        footnoteLabel.textColor = .blackText
        footnoteLabel.font = OpenSans.regular.of(textStyle: .footnote)
        if Environment.sharedInstance.opco == .bge {
            footnoteLabel.text = NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Business customers cannot use VISA.", comment: "")
        } else {
            footnoteLabel.text = NSLocalizedString("We accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.", comment: "")
        }
        
        // BGE only fields should be removed on ComEd/PECO
        if Environment.sharedInstance.opco != .bge {
            nameOnCardTextField.isHidden = true
        }
        
        bindViewModel()
        bindViewHiding()
        bindValidation()
        accessibilityUpdate()
    }
    
    private func accessibilityUpdate() {
        expDateView.accessibilityElements = [expDateLabel, expMonthTextField, expYearTextField]
        cvvZipView.accessibilityElements = [cvvTextField, cvvTooltipButton, zipCodeTextField]
    }
    
    func bindViewModel() {
        nameOnCardTextField.textField.rx.text.orEmpty.bind(to: viewModel.nameOnCard).addDisposableTo(disposeBag)
        cardNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.cardNumber).addDisposableTo(disposeBag)
        expMonthTextField.textField.rx.text.orEmpty.bind(to: viewModel.expMonth).addDisposableTo(disposeBag)
        expYearTextField.textField.rx.text.orEmpty.bind(to: viewModel.expYear).addDisposableTo(disposeBag)
        cvvTextField.textField.rx.text.orEmpty.bind(to: viewModel.cvv).addDisposableTo(disposeBag)
        zipCodeTextField.textField.rx.text.orEmpty.bind(to: viewModel.zipCode).addDisposableTo(disposeBag)
        saveToWalletSwitch.rx.isOn.bind(to: viewModel.saveToWallet).addDisposableTo(disposeBag)
        nicknameTextField.textField.rx.text.orEmpty.bind(to: viewModel.nickname).addDisposableTo(disposeBag)
        oneTouchPaySwitch.rx.isOn.bind(to: viewModel.oneTouchPay).addDisposableTo(disposeBag)
    }
    
    func bindViewHiding() {
        viewModel.paymentWorkflow.asDriver().map(!).drive(saveToWalletStackView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.saveToWallet.asDriver().drive(byNotSavingLabel.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.saveToWallet.asDriver().map(!).drive(nicknameTextField.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.saveToWallet.asDriver().map(!).drive(oneTouchPayView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.paymentWorkflow.asDriver().drive(footnoteLabel.rx.isHidden).addDisposableTo(disposeBag)
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
        
        cardNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.cardNumber.value.isEmpty {
                self.viewModel.cardNumberIsValid().single().subscribe(onNext: { valid in
                    if !valid {
                        self.cardNumberTextField.setError(NSLocalizedString("Invalid card number", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
        }).addDisposableTo(disposeBag)
        
        cardNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.cardNumberTextField.setError(nil)
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
        
        viewModel.nicknameErrorString().subscribe(onNext: { errMessage in
            self.nicknameTextField.setError(errMessage)
        }).addDisposableTo(disposeBag)
    }
    
    @IBAction func onCardIOButtonPress() {
        delegate?.addCardFormViewDidTapCardIOButton(self)
    }
    
    @IBAction func onCVVTooltipPress() {
        delegate?.addCardFormViewDidTapCVVTooltip(self)
    }

}

extension AddCardFormView: UITextFieldDelegate {
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
