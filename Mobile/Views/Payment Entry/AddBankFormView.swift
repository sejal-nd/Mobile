//
//  AddBankFormView.swift
//  Mobile
//
//  Created by Marc Shilling on 7/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

protocol AddBankFormViewDelegate: class {
    func addBankFormViewDidTapRoutingNumberTooltip(_ addBankFormView: AddBankFormView)
    func addBankFormViewDidTapAccountNumberTooltip(_ addBankFormView: AddBankFormView)
}

class AddBankFormView: UIView {
    
    weak var delegate: AddBankFormViewDelegate?
    
    let disposeBag = DisposeBag()

    @IBOutlet weak var view: UIView!
    
    @IBOutlet weak var checkingSavingsSegmentedControl: SegmentedControl!
    @IBOutlet weak var accountHolderNameTextField: FloatLabelTextField!
    @IBOutlet weak var routingNumberTextField: FloatLabelTextField!
    @IBOutlet weak var routingNumberTooltipButton: UIButton!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var accountNumberTooltipButton: UIButton!
    @IBOutlet weak var confirmAccountNumberTextField: FloatLabelTextField!
    
    @IBOutlet weak var saveToWalletStackView: UIStackView!
    @IBOutlet weak var saveToWalletSwitch: Switch!
    @IBOutlet weak var saveToWalletLabel: UILabel!
    @IBOutlet weak var byNotSavingLabel: UILabel!
    
    @IBOutlet weak var nicknameTextField: FloatLabelTextField!
    
    @IBOutlet weak var oneTouchPayView: UIView!
    @IBOutlet weak var oneTouchPayDescriptionLabel: UILabel!
    @IBOutlet weak var oneTouchPaySwitch: Switch!
    @IBOutlet weak var oneTouchPayLabel: UILabel!
    
    var viewModel = AddBankFormViewModel(walletService: ServiceFactory.createWalletService())

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(AddBankFormView.className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
        
        checkingSavingsSegmentedControl.items = [NSLocalizedString("Checking", comment: ""), NSLocalizedString("Savings", comment: "")]
        
        accountHolderNameTextField.textField.placeholder = NSLocalizedString("Bank Account Holder Name*", comment: "")
        accountHolderNameTextField.textField.delegate = self
        accountHolderNameTextField.textField.returnKeyType = .next
        
        routingNumberTextField.textField.placeholder = NSLocalizedString("Routing Number*", comment: "")
        routingNumberTextField.textField.delegate = self
        routingNumberTextField.setKeyboardType(.numberPad)
        routingNumberTextField.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        routingNumberTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        accountNumberTextField.textField.placeholder = NSLocalizedString("Account Number*", comment: "")
        accountNumberTextField.textField.delegate = self
        accountNumberTextField.setKeyboardType(.numberPad)
        accountNumberTextField.textField.isShowingAccessory = true
        accountNumberTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        confirmAccountNumberTextField.textField.placeholder = NSLocalizedString("Confirm Account Number*", comment: "")
        confirmAccountNumberTextField.textField.delegate = self
        confirmAccountNumberTextField.setKeyboardType(.numberPad)
        
        saveToWalletLabel.textColor = .blackText
        saveToWalletLabel.text = NSLocalizedString("Save to My Wallet", comment: "")
        saveToWalletLabel.font = SystemFont.regular.of(textStyle: .headline)
        byNotSavingLabel.textColor = .blackText
        byNotSavingLabel.font = OpenSans.regular.of(textStyle: .footnote)
        byNotSavingLabel.text = NSLocalizedString("By not saving this payment method, you will only be eligible to make an instant payment.", comment: "")
        
        nicknameTextField.textField.placeholder = Environment.shared.opco == .bge ? NSLocalizedString("Nickname*", comment: "") : NSLocalizedString("Nickname (Optional)", comment: "")
        nicknameTextField.textField.autocorrectionType = .no
        
        oneTouchPayDescriptionLabel.textColor = .blackText
        oneTouchPayDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        oneTouchPayLabel.textColor = .blackText
        oneTouchPayLabel.text = NSLocalizedString("Default Payment Method", comment: "")
        oneTouchPayLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        if Environment.shared.opco == .bge {
            saveToWalletStackView.isHidden = true // BGE bank payments must be saved
        } else {
            // BGE only fields
            checkingSavingsSegmentedControl.isHidden = true
            accountHolderNameTextField.isHidden = true
        }
        
        bindViewModel()
        bindViewHiding()
        bindValidation()
    }
    
    func bindViewModel() {
        checkingSavingsSegmentedControl.selectedIndex.asObservable().bind(to: viewModel.selectedSegmentIndex).disposed(by: disposeBag)
        accountHolderNameTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountHolderName).disposed(by: disposeBag)
        routingNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.routingNumber).disposed(by: disposeBag)
        accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).disposed(by: disposeBag)
        confirmAccountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.confirmAccountNumber).disposed(by: disposeBag)
        saveToWalletSwitch.rx.isOn.bind(to: viewModel.saveToWallet).disposed(by: disposeBag)
        nicknameTextField.textField.rx.text.orEmpty.bind(to: viewModel.nickname).disposed(by: disposeBag)
        oneTouchPaySwitch.rx.isOn.bind(to: viewModel.oneTouchPay).disposed(by: disposeBag)
        
        viewModel.confirmAccountNumberIsEnabled.drive(onNext: { [weak self] enabled in
            self?.confirmAccountNumberTextField.setEnabled(enabled)
        }).disposed(by: disposeBag)
    }
    
    func bindViewHiding() {
        viewModel.paymentWorkflow.asDriver().map {
            if Environment.shared.opco == .bge { // BGE MUST save bank
                return true
            }
            return !$0
        }.drive(saveToWalletStackView.rx.isHidden).disposed(by: disposeBag)
        viewModel.saveToWallet.asDriver().drive(byNotSavingLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.saveToWallet.asDriver().map(!).drive(nicknameTextField.rx.isHidden).disposed(by: disposeBag)
        viewModel.saveToWallet.asDriver().map(!).drive(oneTouchPayView.rx.isHidden).disposed(by: disposeBag)
    }
    
    func bindValidation() {
        accountHolderNameTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.accountHolderName.asDriver(), viewModel.accountHolderNameIsValid))
            .filter { !$0.0.isEmpty && !$0.1 }
            .drive(onNext: { [weak self] _ in
                self?.accountHolderNameTextField.setError(NSLocalizedString("Must be at least 3 characters", comment: ""))
            }).disposed(by: disposeBag)
        
        accountHolderNameTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.accountHolderNameTextField.setError(nil)
        }).disposed(by: disposeBag)
        
        routingNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.routingNumber.asDriver(), viewModel.routingNumberIsValid))
            .filter { !$0.0.isEmpty }
            .drive(onNext: { [weak self] _, valid in
                guard let self = self else { return }
                if !valid {
                    self.routingNumberTextField.setError(NSLocalizedString("Must be 9 digits", comment: ""))
                } else {
                    self.viewModel.getBankName(onSuccess: { [weak self] in
                        guard let self = self else { return }
                        self.routingNumberTextField.setInfoMessage(self.viewModel.bankName)
                    }, onError: { [weak self] in
                        self?.routingNumberTextField.setInfoMessage(nil)
                    })
                }
            }).disposed(by: disposeBag)
        
        routingNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver()
            .drive(onNext: { [weak self] in
                self?.routingNumberTextField.setError(nil)
            }).disposed(by: disposeBag)
        
        accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.accountNumber.asDriver(), viewModel.accountNumberIsValid))
            .filter { !$0.0.isEmpty && !$0.1 }
            .drive(onNext: { [weak self] _ in
                self?.accountNumberTextField.setError(NSLocalizedString("Must be between 4-17 digits", comment: ""))
            }).disposed(by: disposeBag)
        
        accountNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.accountNumberTextField.setError(nil)
        }).disposed(by: disposeBag)
        
        viewModel.confirmAccountNumberMatches.drive(onNext: { [weak self] matches in
            guard let self = self else { return }
            if !self.viewModel.confirmAccountNumber.value.isEmpty {
                if matches {
                    self.confirmAccountNumberTextField.setValidated(true, accessibilityLabel: NSLocalizedString("Fields match", comment: ""))
                } else {
                    self.confirmAccountNumberTextField.setError(NSLocalizedString("Account numbers do not match", comment: ""))
                }
            } else {
                self.confirmAccountNumberTextField.setValidated(false)
                self.confirmAccountNumberTextField.setError(nil)
            }
        }).disposed(by: disposeBag)
        
        viewModel.nicknameErrorString.drive(onNext: { [weak self] errMessage in
            self?.nicknameTextField.setError(errMessage)
        }).disposed(by: disposeBag)
    }
    
    @IBAction func onRoutingNumberQuestionMarkPress() {
        self.delegate?.addBankFormViewDidTapRoutingNumberTooltip(self)
    }
    
    @IBAction func onAccountNumberQuestionMarkPress() {
        self.delegate?.addBankFormViewDidTapAccountNumberTooltip(self)
    }
}

extension AddBankFormView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let characterSet = CharacterSet(charactersIn: string)
        if textField == routingNumberTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 9
        } else if textField == accountNumberTextField.textField || textField == confirmAccountNumberTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 17
        }
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField == routingNumberTextField.textField {
            if textField.text?.count == 9 {
                accountNumberTextField.textField.becomeFirstResponder()
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == accountHolderNameTextField.textField {
            routingNumberTextField.textField.becomeFirstResponder()
        }
        return false
    }
}
