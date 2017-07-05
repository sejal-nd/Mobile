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

class AutoPayChangeBankViewController: UIViewController {
	
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var checkingSavingsSegmentedControl: SegmentedControl!
	@IBOutlet weak var nameTextField: FloatLabelTextField!
	@IBOutlet weak var routingNumberTextField: FloatLabelTextField!
	@IBOutlet weak var routingNumberTooltipButton: UIButton!
	@IBOutlet weak var accountNumberTextField: FloatLabelTextField!
	@IBOutlet weak var accountNumberTooltipButton: UIButton!
	@IBOutlet weak var confirmAccountNumberTextField: FloatLabelTextField!
	
	@IBOutlet weak var tacStackView: UIStackView!
	@IBOutlet weak var tacSwitch: Switch!
	@IBOutlet weak var tacLabel: UILabel!
	@IBOutlet weak var tacButton: UIButton!
	
	@IBOutlet weak var footerLabel: UILabel!
	
	let bag = DisposeBag()
	
	var viewModel: AutoPayViewModel!
	
	weak var delegate: AutoPayChangeBankViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Change Bank Account", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: #selector(onSavePress))
        navigationItem.leftBarButtonItem = cancelButton
		navigationItem.rightBarButtonItem = saveButton
		
		NotificationCenter.default.rx.notification(.UIKeyboardWillShow, object: nil)
			.asDriver(onErrorDriveWith: Driver.empty())
			.drive(onNext: keyboardWillShow)
			.addDisposableTo(bag)
		
		NotificationCenter.default.rx.notification(.UIKeyboardWillHide, object: nil)
			.asDriver(onErrorDriveWith: Driver.empty())
			.drive(onNext: keyboardWillHide)
			.addDisposableTo(bag)
		
		style()
		textFieldSetup()
		bindViews()
		
		viewModel.canSubmitNewAccount.drive(saveButton.rx.isEnabled).addDisposableTo(bag)
	}
	
	private func style() {
		tacLabel.text = NSLocalizedString("Yes, I have read, understand and agree to the terms and conditions below, and by checking this box, I authorize ComEd to regularly debit the bank account provided.\n\nI understand that my bank account will be automatically debited each billing period for the total amount due, that these are variable charges, and that my bill being posted in the ComEd mobile app acts as my notification.\n\nCustomers can see their bill monthly through the ComEd mobile app. Bills are delivered online during each billing cycle. Please note that this will not change your preferred bill delivery method.\n", comment: "")
		tacLabel.font = SystemFont.regular.of(textStyle: .headline)
		tacLabel.setLineHeight(lineHeight: 25)
		tacButton.titleLabel?.font = SystemFont.bold.of(textStyle: .headline)
	}
	
	private func textFieldSetup() {
		nameTextField.textField.placeholder = NSLocalizedString("Name on Account*", comment: "")
		nameTextField.textField.delegate = self
		nameTextField.textField.returnKeyType = .next
		
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
		confirmAccountNumberTextField.textField.returnKeyType = .done
	}
	
	private func bindViews() {
		
		checkingSavingsSegmentedControl.items = [NSLocalizedString("Checking", comment: ""), NSLocalizedString("Savings", comment: "")]
		
		checkingSavingsSegmentedControl.selectedIndex.asObservable()
			.map { selectedIndex -> BankAccountType in
				selectedIndex == 0 ? .checking: .savings
			}
			.bind(to: viewModel.bankAccountType)
			.addDisposableTo(bag)
		
		tacButton.rx.tap.asDriver()
			.drive(onNext: onTermsAndConditionsPress)
			.addDisposableTo(bag)
		
		nameTextField.textField.rx.text.orEmpty.bind(to: viewModel.nameOnAccount).addDisposableTo(bag)
		accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).addDisposableTo(bag)
		routingNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.routingNumber).addDisposableTo(bag)
		confirmAccountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.confirmAccountNumber).addDisposableTo(bag)
		tacSwitch.rx.isOn.bind(to: viewModel.termsAndConditionsCheck).addDisposableTo(bag)
		tacStackView.isHidden = !viewModel.shouldShowTermsAndConditionsCheck

		// Name on Account
		viewModel.nameOnAccountErrorText
			.drive(onNext: { [weak self] errorText in
				self?.nameTextField.setError(errorText)
			})
			.addDisposableTo(bag)
		
		// Routing Numbe
		let routingNumberErrorTextFocused: Driver<String?> = routingNumberTextField.textField.rx
			.controlEvent(.editingDidBegin).asDriver()
			.map{ nil }
        
        let routingNumberErrorTextUnfocused: Driver<String?> = routingNumberTextField.textField.rx
            .controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(viewModel.getBankName)
		
		Driver.merge(routingNumberErrorTextFocused, routingNumberErrorTextUnfocused)
			.distinctUntilChanged(==)
			.drive(onNext: { [weak self] errorText in
				self?.routingNumberTextField.setError(errorText)
			})
			.addDisposableTo(bag)
		
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
			})
			.addDisposableTo(bag)
		
		// Confirm Account Number
		viewModel.confirmAccountNumberErrorText
			.drive(onNext: { [weak self] errorText in
				self?.confirmAccountNumberTextField.setError(errorText)
			})
			.addDisposableTo(bag)
		
		viewModel.confirmAccountNumberIsValid
			.drive(onNext: { [weak self] validated in
				self?.confirmAccountNumberTextField.setValidated(validated, accessibilityLabel: NSLocalizedString("Fields match", comment: ""))
			})
			.addDisposableTo(bag)
		
		viewModel.confirmAccountNumberIsEnabled
			.drive(onNext: { [weak self] enabled in
				self?.confirmAccountNumberTextField.setEnabled(enabled)
			})
			.addDisposableTo(bag)
		
		
		routingNumberTooltipButton.rx.tap.asDriver()
			.drive(onNext: onRoutingNumberQuestionMarkPress)
			.addDisposableTo(bag)
		
		accountNumberTooltipButton.rx.tap.asDriver()
			.drive(onNext: onAccountNumberQuestionMarkPress)
			.addDisposableTo(bag)
		
		viewModel.footerText.drive(footerLabel.rx.text).addDisposableTo(bag)
	}
	
	
	func onTermsAndConditionsPress() {
		let tacModal = WebViewController(title: NSLocalizedString("Terms and Conditions", comment: ""),
		                                 url: URL(string:"https://webpayments.billmatrix.com/HTML/terms_conditions_en-us.html")!)
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
	
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    
    func onSavePress() {
        LoadingView.show()
        viewModel.submit()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] enrolled in
                    LoadingView.hide()
                    guard let strongSelf = self else { return }
                    strongSelf.delegate?.changedBank()
                    strongSelf.navigationController?.popViewController(animated: true)
                }, onError: { [weak self] error in
                    LoadingView.hide()
                    guard let strongSelf = self else { return }
                    let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                                            message: error.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    strongSelf.present(alertController, animated: true, completion: nil)
            })
            .addDisposableTo(bag)
    }
	
}

extension AutoPayChangeBankViewController: UITextFieldDelegate {
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		let characterSet = CharacterSet(charactersIn: string)
		if textField == routingNumberTextField.textField {
			return CharacterSet.decimalDigits.isSuperset(of: characterSet)
		} else if textField == accountNumberTextField.textField || textField == confirmAccountNumberTextField.textField {
			return CharacterSet.decimalDigits.isSuperset(of: characterSet)
		}
		return true
	}
	
	func textFieldDidChange(_ textField: UITextField) {
		if textField == routingNumberTextField.textField {
			accountNumberTextField.textField.becomeFirstResponder()
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField == nameTextField.textField {
			routingNumberTextField.textField.becomeFirstResponder()
		} else if textField == routingNumberTextField.textField {
			accountNumberTextField.textField.becomeFirstResponder()
		} else if textField == accountNumberTextField.textField {
			if confirmAccountNumberTextField.isUserInteractionEnabled {
				confirmAccountNumberTextField.textField.becomeFirstResponder()
			}
		} else if textField == confirmAccountNumberTextField.textField {
			textField.resignFirstResponder()
		}
		return false
	}
}

