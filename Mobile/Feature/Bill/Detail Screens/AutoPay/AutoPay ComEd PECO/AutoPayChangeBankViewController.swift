//
//  AutoPayChangeBankViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol AutoPayChangeBankViewControllerDelegate: class {
	func changedBank()
}

class AutoPayChangeBankViewController: KeyboardAvoidingStickyFooterViewController {
	
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var checkingSavingsSegmentedControl: SegmentedControl!
	@IBOutlet weak var nameTextField: FloatLabelTextField!
	@IBOutlet weak var routingNumberTextField: FloatLabelTextField!
	@IBOutlet weak var routingNumberTooltipButton: UIButton!
	@IBOutlet weak var accountNumberTextField: FloatLabelTextField!
	@IBOutlet weak var accountNumberTooltipButton: UIButton!
	@IBOutlet weak var confirmAccountNumberTextField: FloatLabelTextField!
	
	@IBOutlet weak var tacStackView: UIStackView!
	@IBOutlet weak var tacSwitch: Checkbox!
	@IBOutlet weak var tacLabel: UILabel!
	@IBOutlet weak var tacButton: UIButton!
	
	@IBOutlet weak var footerLabel: UILabel!
	
    @IBOutlet weak var stickyFooterView: StickyFooterView!
    @IBOutlet weak var enrollButton: PrimaryButton!
    
	let bag = DisposeBag()
	
	var viewModel: AutoPayViewModel!
    
	weak var delegate: AutoPayChangeBankViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        addCloseButton()
		style()
        configureView()
		textFieldSetup()
		bindViews()
	}
	
    override func viewDidAppear(_ animated: Bool) {
        GoogleAnalytics.log(event: .autoPayModifyBankView)
    }
    
    
    // MARK: - Helper
    
    private func configureView() {
        title = NSLocalizedString("Change Bank Account", comment: "")
        viewModel.canSubmitNewAccount.drive(enrollButton.rx.isEnabled).disposed(by: bag)
    }
    
	private func style() {
		tacLabel.text = NSLocalizedString("Yes, I have read, understand and agree to the terms and conditions below, and by checking this box, I authorize ComEd to regularly debit the bank account provided.\n\nI understand that my bank account will be automatically debited each billing period for the total amount due, that these are variable charges, and that my bill being posted in the ComEd mobile app acts as my notification.\n\nCustomers can see their bill monthly through the ComEd mobile app. Bills are delivered online during each billing cycle. Please note that this will not change your preferred bill delivery method.\n", comment: "")
        tacLabel.textColor = .deepGray
		tacLabel.font = SystemFont.regular.of(textStyle: .subheadline)
		tacLabel.setLineHeight(lineHeight: 25)
        tacSwitch.accessibilityLabel = "I agree to ComEd’s AutoPay Terms and Conditions"
		tacButton.titleLabel?.font = SystemFont.bold.of(textStyle: .subheadline)
        footerLabel.textColor = .deepGray
        footerLabel.font = SystemFont.regular.of(textStyle: .footnote)
        footerLabel.setLineHeight(lineHeight: 16)
	}
	
	private func textFieldSetup() {
		nameTextField.placeholder = NSLocalizedString("Name on Account*", comment: "")
		nameTextField.textField.delegate = self
		nameTextField.textField.returnKeyType = .next
		
		routingNumberTextField.placeholder = NSLocalizedString("Routing Number*", comment: "")
		routingNumberTextField.textField.delegate = self
		routingNumberTextField.setKeyboardType(.numberPad)
		routingNumberTextField.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
		routingNumberTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
		
		accountNumberTextField.placeholder = NSLocalizedString("Account Number*", comment: "")
		accountNumberTextField.textField.delegate = self
		accountNumberTextField.setKeyboardType(.numberPad)
		accountNumberTextField.textField.isShowingAccessory = true
		accountNumberTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
		
		confirmAccountNumberTextField.placeholder = NSLocalizedString("Confirm Account Number*", comment: "")
		confirmAccountNumberTextField.textField.delegate = self
		confirmAccountNumberTextField.setKeyboardType(.numberPad)
	}
	
    
    // MARK: - Bindings
    
	private func bindViews() {
        checkingSavingsSegmentedControl.items = [
            NSLocalizedString("Checking", comment: ""),
            NSLocalizedString("Savings", comment: "")
        ]
        checkingSavingsSegmentedControl.selectedIndex.asObservable().bind(to: viewModel.checkingSavingsSegmentedControlIndex).disposed(by: bag)
		
		tacButton.rx.tap.asDriver()
			.drive(onNext: onTermsAndConditionsPress)
			.disposed(by: bag)
		
		nameTextField.textField.rx.text.orEmpty.bind(to: viewModel.nameOnAccount).disposed(by: bag)
		accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).disposed(by: bag)
		routingNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.routingNumber).disposed(by: bag)
		confirmAccountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.confirmAccountNumber).disposed(by: bag)
		tacSwitch.rx.isChecked.bind(to: viewModel.termsAndConditionsCheck).disposed(by: bag)
		tacStackView.isHidden = !viewModel.shouldShowTermsAndConditionsCheck

		// Name on Account
		viewModel.nameOnAccountErrorText
			.drive(onNext: { [weak self] errorText in
				self?.nameTextField.setError(errorText)
                self?.accessibilityErrorLabel()
                
			})
			.disposed(by: bag)
		
		// Routing Number
        let routingNumberErrorTextFocused: Driver<String?> = routingNumberTextField.textField.rx
            .controlEvent(.editingDidBegin).asDriver()
            .map{ nil }
        
        routingNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.routingNumberTextField.setError(nil)
            self.accessibilityErrorLabel()
            
        }).disposed(by: bag)
        
        let routingNumberErrorTextUnfocused: Driver<String?> = routingNumberTextField.textField.rx
            .controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(viewModel.routingNumberErrorText)
        
        
        routingNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if self.viewModel.routingNumber.value.count == 9 {
                self.viewModel.getBankName(onSuccess: {
                    self.routingNumberTextField.setInfoMessage(self.viewModel.bankName)
                }, onError: {
                    self.routingNumberTextField.setInfoMessage(nil)
                })
            }
        }).disposed(by: bag)
        
        Driver.merge(routingNumberErrorTextFocused, routingNumberErrorTextUnfocused)
            .distinctUntilChanged(==)
            .drive(onNext: { [weak self] errorText in
                self?.routingNumberTextField.setError(errorText)
                self?.accessibilityErrorLabel()
                
            })
            .disposed(by: bag)
		
		// Account Number
		let accountNumberErrorTextFocused: Driver<String?> = accountNumberTextField.textField.rx
			.controlEvent(.editingDidBegin).asDriver()
			.map{ nil }
		
		let accountNumberErrorTextUnfocused: Driver<String?> = accountNumberTextField.textField.rx
			.controlEvent(.editingDidEnd).asDriver()
			.withLatestFrom(viewModel.accountNumberErrorText)
		
		Driver.merge(accountNumberErrorTextFocused, accountNumberErrorTextUnfocused)
			.distinctUntilChanged(==)
			.drive(onNext: { [weak self] errorText in
				self?.accountNumberTextField.setError(errorText)
                self?.accessibilityErrorLabel()
                
			})
			.disposed(by: bag)
		
		// Confirm Account Number
		viewModel.confirmAccountNumberErrorText
			.drive(onNext: { [weak self] errorText in
				self?.confirmAccountNumberTextField.setError(errorText)
                self?.accessibilityErrorLabel()
                
			})
			.disposed(by: bag)
		
		viewModel.confirmAccountNumberIsValid
			.drive(onNext: { [weak self] validated in
				self?.confirmAccountNumberTextField.setValidated(validated, accessibilityLabel: NSLocalizedString("Fields match", comment: ""))
			})
			.disposed(by: bag)
		
		viewModel.confirmAccountNumberIsEnabled
			.drive(onNext: { [weak self] enabled in
				self?.confirmAccountNumberTextField.setEnabled(enabled)
			})
			.disposed(by: bag)
		
		
		routingNumberTooltipButton.rx.tap.asDriver()
			.drive(onNext: onRoutingNumberQuestionMarkPress)
			.disposed(by: bag)
		
		accountNumberTooltipButton.rx.tap.asDriver()
			.drive(onNext: onAccountNumberQuestionMarkPress)
			.disposed(by: bag)
		
		viewModel.footerText.drive(footerLabel.rx.text).disposed(by: bag)
	}
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += nameTextField.getError()
        message += routingNumberTextField.getError()
        message += accountNumberTextField.getError()
        message += confirmAccountNumberTextField.getError()
        
        if message.isEmpty {
            enrollButton.accessibilityLabel = NSLocalizedString("Save", comment: "")
        } else {
            enrollButton.accessibilityLabel = String(format: NSLocalizedString("%@ Save", comment: ""), message)
        }
    }
	
    
    // MARK: - Actions
    
	@objc
	func onTermsAndConditionsPress() {
		let tacModal = WebViewController(title: NSLocalizedString("Terms and Conditions", comment: ""),
		                                 url: URL(string: "https://webpayments.billmatrix.com/HTML/terms_conditions_en-us.html")!)
		navigationController?.present(tacModal, animated: true, completion: nil)
	}
	
	func onRoutingNumberQuestionMarkPress() {
		let infoModal = InfoModalViewController(title: NSLocalizedString("Routing Number", comment: ""), image: #imageLiteral(resourceName: "routing_number_info"), description: NSLocalizedString("This number is used to identify your banking institution. You can find your bank’s nine-digit routing number on the bottom of your paper check.", comment: ""))
		navigationController?.present(infoModal, animated: true, completion: nil)
	}
	
	func onAccountNumberQuestionMarkPress() {
		let infoModal = InfoModalViewController(title: NSLocalizedString("Account Number", comment: ""), image: #imageLiteral(resourceName: "account_number_info"), description: NSLocalizedString("This number is used to identify your bank account. You can find your checking account number on the bottom of your paper check following the routing number.", comment: ""))
		navigationController?.present(infoModal, animated: true, completion: nil)
	}

    @IBAction func onSavePress() {
        view.endEditing(true)
        
        LoadingView.show()
        GoogleAnalytics.log(event: .autoPayModifyBankSave)
        viewModel.changeBank()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] enrolled in
                LoadingView.hide()
                guard let self = self else { return }
                self.delegate?.changedBank()
                self.dismissModal()
            }, onError: { [weak self] error in
                LoadingView.hide()
                guard let self = self else { return }
                let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                                        message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            })
            .disposed(by: bag)
    }
	
}


// MARK: - Text Field Delegate

extension AutoPayChangeBankViewController: UITextFieldDelegate {
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
		if textField == routingNumberTextField.textField && textField.text?.count == 9 {
			accountNumberTextField.textField.becomeFirstResponder()
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField == nameTextField.textField {
			routingNumberTextField.textField.becomeFirstResponder()
		}
		return false
	}
}

