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
        routingNumberTextField.textField.returnKeyType = .next
        routingNumberTextField.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        routingNumberTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        accountNumberTextField.textField.placeholder = NSLocalizedString("Account Number*", comment: "")
        accountNumberTextField.textField.delegate = self
        accountNumberTextField.textField.returnKeyType = .next
        accountNumberTextField.textField.isShowingAccessory = true
        accountNumberTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        confirmAccountNumberTextField.textField.placeholder = NSLocalizedString("Confirm Account Number*", comment: "")
        confirmAccountNumberTextField.textField.delegate = self
        confirmAccountNumberTextField.textField.returnKeyType = .next
        
        saveToWalletLabel.textColor = .deepGray
        saveToWalletLabel.text = NSLocalizedString("Save to My Wallet", comment: "")
        byNotSavingLabel.textColor = .blackText
        byNotSavingLabel.font = OpenSans.regular.of(textStyle: .footnote)
        byNotSavingLabel.text = NSLocalizedString("By not saving this payment account, you will only be eligible to make an instant payment.", comment: "")
        
        nicknameTextField.textField.placeholder = Environment.sharedInstance.opco == .bge ? NSLocalizedString("Nickname*", comment: "") : NSLocalizedString("Nickname (Optional)", comment: "")
        nicknameTextField.textField.autocorrectionType = .no
        
        oneTouchPayDescriptionLabel.textColor = .blackText
        oneTouchPayDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        oneTouchPayLabel.textColor = .blackText
        oneTouchPayLabel.text = NSLocalizedString("One Touch Pay", comment: "")
        
        if Environment.sharedInstance.opco == .bge {
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
        checkingSavingsSegmentedControl.selectedIndex.asObservable().bind(to: viewModel.selectedSegmentIndex).addDisposableTo(disposeBag)
        accountHolderNameTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountHolderName).addDisposableTo(disposeBag)
        routingNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.routingNumber).addDisposableTo(disposeBag)
        accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).addDisposableTo(disposeBag)
        confirmAccountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.confirmAccountNumber).addDisposableTo(disposeBag)
        saveToWalletSwitch.rx.isOn.bind(to: viewModel.saveToWallet).addDisposableTo(disposeBag)
        nicknameTextField.textField.rx.text.orEmpty.bind(to: viewModel.nickname).addDisposableTo(disposeBag)
        oneTouchPaySwitch.rx.isOn.bind(to: viewModel.oneTouchPay).addDisposableTo(disposeBag)
        
        viewModel.confirmAccountNumberIsEnabled.drive(onNext: { enabled in
            self.confirmAccountNumberTextField.setEnabled(enabled)
        }).addDisposableTo(disposeBag)
    }
    
    func bindViewHiding() {
        viewModel.paymentWorkflow.asDriver().map {
            if Environment.sharedInstance.opco == .bge { // BGE MUST save bank
                return true
            }
            return !$0
        }.drive(saveToWalletStackView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.saveToWallet.asDriver().drive(byNotSavingLabel.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.saveToWallet.asDriver().map(!).drive(nicknameTextField.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.saveToWallet.asDriver().map(!).drive(oneTouchPayView.rx.isHidden).addDisposableTo(disposeBag)
    }
    
    func bindValidation() {
        accountHolderNameTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.accountHolderName.value.isEmpty {
                self.viewModel.accountHolderNameIsValid().single().subscribe(onNext: { valid in
                    if !valid {
                        self.accountHolderNameTextField.setError(NSLocalizedString("Must be longer than 3 characters", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
        }).addDisposableTo(disposeBag)
        
        accountHolderNameTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.accountHolderNameTextField.setError(nil)
        }).addDisposableTo(disposeBag)
        
        routingNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.routingNumber.value.isEmpty {
                self.viewModel.routingNumberIsValid().single().subscribe(onNext: { valid in
                    if !valid {
                        self.routingNumberTextField.setError(NSLocalizedString("Must be 9 digits", comment: ""))
                    } else {
                        self.viewModel.getBankName(onSuccess: {
                            self.routingNumberTextField.setInfoMessage(self.viewModel.bankName)
                        }, onError: {
                            self.routingNumberTextField.setInfoMessage(nil)
                        })
                    }
                }).addDisposableTo(self.disposeBag)
                
            }
        }).addDisposableTo(disposeBag)
        
        routingNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.routingNumberTextField.setError(nil)
        }).addDisposableTo(disposeBag)
        
        accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if !self.viewModel.accountNumber.value.isEmpty {
                self.viewModel.accountNumberIsValid().single().subscribe(onNext: { valid in
                    if !valid {
                        self.accountNumberTextField.setError(NSLocalizedString("Must be between 4-17 digits", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
        }).addDisposableTo(disposeBag)
        
        accountNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.accountNumberTextField.setError(nil)
        }).addDisposableTo(disposeBag)
        
        viewModel.confirmAccountNumberMatches().subscribe(onNext: { matches in
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
        }).addDisposableTo(disposeBag)
        
        viewModel.nicknameErrorString().subscribe(onNext: { errMessage in
            self.nicknameTextField.setError(errMessage)
        }).addDisposableTo(disposeBag)
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
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 9
        } else if textField == accountNumberTextField.textField || textField == confirmAccountNumberTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 17
        }
        return true
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        if textField == routingNumberTextField.textField {
            if textField.text?.characters.count == 9 {
                accountNumberTextField.textField.becomeFirstResponder()
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if Environment.sharedInstance.opco == .bge {
            if textField == accountHolderNameTextField.textField {
                routingNumberTextField.textField.becomeFirstResponder()
            } else if textField == routingNumberTextField.textField {
                accountNumberTextField.textField.becomeFirstResponder()
            } else if textField == accountNumberTextField.textField {
                if confirmAccountNumberTextField.isUserInteractionEnabled {
                    confirmAccountNumberTextField.textField.becomeFirstResponder()
                }
            } else if textField == confirmAccountNumberTextField.textField {
                nicknameTextField.textField.becomeFirstResponder()
            }
        } else {
            if textField == routingNumberTextField.textField {
                accountNumberTextField.textField.becomeFirstResponder()
            } else if textField == accountNumberTextField.textField {
                if confirmAccountNumberTextField.isUserInteractionEnabled {
                    confirmAccountNumberTextField.textField.becomeFirstResponder()
                }
            } else if textField == confirmAccountNumberTextField.textField {
                nicknameTextField.textField.becomeFirstResponder()
            }
        }
        return false
    }
}
