//
//  AddCardFormView.swift
//  Mobile
//
//  Created by Marc Shilling on 7/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

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
        cardNumberTextField.setKeyboardType(.numberPad)
        cardNumberTextField.textField.isShowingAccessory = true
        cardIOButton.accessibilityLabel = NSLocalizedString("Take a photo to scan credit card number", comment: "")
        
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
        
        saveToWalletLabel.textColor = .blackText
        saveToWalletLabel.text = NSLocalizedString("Save to My Wallet", comment: "")
        saveToWalletLabel.font = SystemFont.regular.of(textStyle: .headline)
        byNotSavingLabel.textColor = .blackText
        byNotSavingLabel.font = OpenSans.regular.of(textStyle: .footnote)
        byNotSavingLabel.text = NSLocalizedString("By not saving this payment method, you will only be eligible to make an instant payment.", comment: "")
        
        nicknameTextField.textField.placeholder = Environment.shared.opco == .bge ? NSLocalizedString("Nickname*", comment: "") : NSLocalizedString("Nickname (Optional)", comment: "")
        
        oneTouchPayDescriptionLabel.textColor = .blackText
        oneTouchPayDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        oneTouchPayLabel.textColor = .blackText
        oneTouchPayLabel.text = NSLocalizedString("Default Payment Method", comment: "")
        oneTouchPayLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        footnoteLabel.textColor = .blackText
        footnoteLabel.font = OpenSans.regular.of(textStyle: .footnote)
        if Environment.shared.opco == .bge {
            footnoteLabel.text = NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Business customers cannot use VISA.", comment: "")
        } else {
            footnoteLabel.text = NSLocalizedString("We accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.", comment: "")
        }
        
        // BGE only fields should be removed on ComEd/PECO
        if Environment.shared.opco != .bge {
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
        nameOnCardTextField.textField.rx.text.orEmpty.bind(to: viewModel.nameOnCard).disposed(by: disposeBag)
        cardNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.cardNumber).disposed(by: disposeBag)
        expMonthTextField.textField.rx.text.orEmpty.bind(to: viewModel.expMonth).disposed(by: disposeBag)
        expYearTextField.textField.rx.text.orEmpty.bind(to: viewModel.expYear).disposed(by: disposeBag)
        cvvTextField.textField.rx.text.orEmpty.bind(to: viewModel.cvv).disposed(by: disposeBag)
        zipCodeTextField.textField.rx.text.orEmpty.bind(to: viewModel.zipCode).disposed(by: disposeBag)
        saveToWalletSwitch.rx.isOn.bind(to: viewModel.saveToWallet).disposed(by: disposeBag)
        nicknameTextField.textField.rx.text.orEmpty.bind(to: viewModel.nickname).disposed(by: disposeBag)
        oneTouchPaySwitch.rx.isOn.bind(to: viewModel.oneTouchPay).disposed(by: disposeBag)
    }
    
    func bindViewHiding() {
        viewModel.paymentWorkflow.asDriver().map(!).drive(saveToWalletStackView.rx.isHidden).disposed(by: disposeBag)
        viewModel.saveToWallet.asDriver().drive(byNotSavingLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.saveToWallet.asDriver().map(!).drive(nicknameTextField.rx.isHidden).disposed(by: disposeBag)
        viewModel.saveToWallet.asDriver().map(!).drive(oneTouchPayView.rx.isHidden).disposed(by: disposeBag)
        viewModel.paymentWorkflow.asDriver().drive(footnoteLabel.rx.isHidden).disposed(by: disposeBag)
    }
    
    func bindValidation() {
        viewModel.cardNumber.asDriver().drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            if let cardIcon = self.viewModel.cardIcon {
                self.cardLogoImageView.image = cardIcon
                self.cardNumberTextField.textField.isShowingLeftAccessory = true
            } else {
                self.cardLogoImageView.image = nil
                self.cardNumberTextField.textField.isShowingLeftAccessory = false
            }
        }).disposed(by: disposeBag)
        
        expMonthTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.expMonth.asDriver(), viewModel.expMonthIsValidMonth, viewModel.expMonthIs2Digits))
            .filter { !$0.0.isEmpty }
            .drive(onNext: { [weak self] _, expMonthIsValidMonth, expMonthIs2Digits  in
                guard let self = self else { return }
                if !expMonthIsValidMonth {
                    self.expMonthTextField.setError(NSLocalizedString("Invalid Month", comment: ""))
                } else if !expMonthIs2Digits {
                    self.expMonthTextField.setError(NSLocalizedString("Must be 2 digits", comment: ""))
                }
            }).disposed(by: self.disposeBag)
        
        
        expMonthTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.expMonthTextField.setError(nil)
        }).disposed(by: disposeBag)
        
        cardNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.cardNumber.asDriver(), viewModel.cardNumberIsValid))
            .filter { !$0.0.isEmpty && !$0.1 }
            .drive(onNext: { [weak self] _ in
                self?.cardNumberTextField.setError(NSLocalizedString("Invalid card number", comment: ""))
            }).disposed(by: disposeBag)
        
        cardNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.cardNumberTextField.setError(nil)
        }).disposed(by: disposeBag)
        
        expYearTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.expYear.asDriver(), viewModel.expYearIsNotInPast, viewModel.expYearIs4Digits))
            .filter { !$0.0.isEmpty }
            .drive(onNext: { [weak self] _, expYearIsNotInPast, expYearIs4Digits  in
                guard let self = self else { return }
                if !expYearIsNotInPast {
                    self.expYearTextField.setError(NSLocalizedString("Cannot be in the past", comment: ""))
                } else if !expYearIs4Digits {
                    self.expYearTextField.setError(NSLocalizedString("Must be 4 digits", comment: ""))
                }
            }).disposed(by: self.disposeBag)
        
        expYearTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.expYearTextField.setError(nil)
        }).disposed(by: disposeBag)
        
        cvvTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.cvv.asDriver(), viewModel.cvvIsCorrectLength))
            .filter { !$0.0.isEmpty && !$0.1 }
            .drive(onNext: { [weak self] _ in
                self?.cvvTextField.setError(NSLocalizedString("Must be 3 or 4 digits", comment: ""))
            }).disposed(by: disposeBag)
        
        cvvTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.cvvTextField.setError(nil)
        }).disposed(by: disposeBag)
        
        zipCodeTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.zipCode.asDriver(), viewModel.zipCodeIs5Digits))
            .filter { !$0.0.isEmpty && !$0.1 }
            .drive(onNext: { [weak self] _ in
                self?.zipCodeTextField.setError(NSLocalizedString("Must be 5 digits", comment: ""))
            }).disposed(by: disposeBag)
        
        zipCodeTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.zipCodeTextField.setError(nil)
        }).disposed(by: disposeBag)
        
        viewModel.nicknameErrorString.drive(onNext: { [weak self] errMessage in
            self?.nicknameTextField.setError(errMessage)
        }).disposed(by: disposeBag)
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
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 19
        } else if textField == expMonthTextField.textField {
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameOnCardTextField.textField {
            cardNumberTextField.textField.becomeFirstResponder()
        }
        return false
    }
    
}
