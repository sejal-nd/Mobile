//
//  AutoPayViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol AutoPayViewControllerDelegate: class {
    func autoPayViewController(_ autoPayViewController: UIViewController, enrolled: Bool)
}

class AutoPayViewController: KeyboardAvoidingStickyFooterViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    
    // Not Enrolled
    @IBOutlet weak var enrollStackView: UIStackView!
    @IBOutlet weak var topLabel: UILabel!
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
    
    // Enrolled
    @IBOutlet weak var enrolledStackView: UIStackView!
    @IBOutlet weak var enrolledContentView: UIView!
    @IBOutlet weak var enrolledTopLabel: UILabel!
    
    // Unenrolling
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    @IBOutlet weak var stickyFooterView: StickyFooterView!
    @IBOutlet weak var enrollButton: PrimaryButton!
    @IBOutlet weak var unenrollView: UIView!
    @IBOutlet weak var unenrollButtonLabel: UILabel!
    @IBOutlet weak var unenrollButton: UIButton!
        
    weak var delegate: AutoPayViewControllerDelegate?
    
    let bag = DisposeBag()
    
    var accountDetail: AccountDetail!

    lazy var viewModel: AutoPayViewModel = { AutoPayViewModel( accountDetail: self.accountDetail) }()

    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        style()
        configureView()
        textFieldSetup()
        bindStates()
        
        viewModel.footerText.drive(footerLabel.rx.text).disposed(by: bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        FirebaseUtility.logEvent(.autoPayStart)
        
        if viewModel.enrollmentStatus.value == .enrolled {
            FirebaseUtility.logScreenView(.AutopayEnrolledView(className: self.className))
        } else {
            FirebaseUtility.logScreenView(.AutopayUnenrolledView(className: self.className))
        }
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? LargeTitleNavigationController,
            let vc = nav.viewControllers.first as? AutoPayChangeBankViewController {
            vc.viewModel = viewModel
            vc.delegate = self
        } else if let nav = segue.destination as? LargeTitleNavigationController,
            let vc = nav.viewControllers.first as? AutoPayReasonsForStoppingViewController {
            vc.viewModel = viewModel
            vc.delegate = delegate
            vc.parentVc = self
        }
    }
    
    
    // MARK: - Helper
    
    private func configureView() {
        title = NSLocalizedString("AutoPay", comment: "")
        
        let helpButton = UIBarButtonItem(image: UIImage(named: "ic_tooltip"), style: .plain, target: self, action: #selector(onLearnMorePress))
        helpButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        navigationItem.rightBarButtonItem = helpButton
        
        viewModel.canSubmitNewAccount.drive(enrollButton.rx.isEnabled).disposed(by: bag)
        
        if accountDetail.isAutoPay {
            enrollButton.isHidden = true
        } else {
            unenrollView.isHidden = true
        }
    }
    
    private func style() {
        if accountDetail.isAutoPay {
            // Enrolled
            enrolledTopLabel.textColor = .deepGray
            enrolledTopLabel.font = SystemFont.regular.of(textStyle: .headline)
            enrolledTopLabel.setLineHeight(lineHeight: 16)
            
            unenrollButtonLabel.textColor = .deepGray
            unenrollButtonLabel.font = SystemFont.regular.of(textStyle: .subheadline)
            
            unenrollButton.titleLabel?.font = SystemFont.bold.of(textStyle: .subheadline)
        } else {
            // Not enrolled
            topLabel.textColor = .deepGray
            topLabel.font = SystemFont.regular.of(textStyle: .headline)
            topLabel.setLineHeight(lineHeight: 24)
            
            tacLabel.textColor = .deepGray
            tacLabel.text = viewModel.tacLabelText
            tacLabel.font = SystemFont.regular.of(textStyle: .subheadline)
            tacLabel.setLineHeight(lineHeight: 25)
            tacSwitch.accessibilityLabel = viewModel.tacSwitchAccessibilityLabel
            tacButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .subheadline)
            GoogleAnalytics.log(event: .autoPayEnrollOffer)
        }

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
    
    private func bindStates() {
        viewModel.enrollmentStatus.asDriver().map { $0 == .unenrolled }.drive(enrolledStackView.rx.isHidden).disposed(by: bag)
        viewModel.enrollmentStatus.asDriver().map { $0 == .enrolled }.drive(enrollStackView.rx.isHidden).disposed(by: bag)
        
        checkingSavingsSegmentedControl.items = [
            NSLocalizedString("Checking", comment: ""),
            NSLocalizedString("Savings", comment: "")
        ]
        checkingSavingsSegmentedControl.selectedIndex.asObservable().bind(to: viewModel.checkingSavingsSegmentedControlIndex).disposed(by: bag)
        
        tacButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                self?.onTermsAndConditionsPress()
            })
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
        routingNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.routingNumberTextField.setError(nil)
            self?.accessibilityErrorLabel()
            
        }).disposed(by: bag)
        
        let routingNumberErrorTextUnfocused: Driver<String?> = routingNumberTextField.textField.rx
            .controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(viewModel.routingNumberErrorText)
        
        routingNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver().drive(onNext: { [weak self] in
            guard let self = self else { return }
            if self.viewModel.routingNumber.value.count == 9 {
                self.viewModel.getBankName(onSuccess: { [weak self] in
                    guard let self = self else { return }
                    self.routingNumberTextField.setInfoMessage(self.viewModel.bankName)
                    }, onError: { [weak self] in
                        self?.routingNumberTextField.setInfoMessage(nil)
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
            .drive(onNext: { [weak self] in
                self?.onRoutingNumberQuestionMarkPress()
            })
            .disposed(by: bag)
        
        accountNumberTooltipButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                self?.onAccountNumberQuestionMarkPress()
            })
            .disposed(by: bag)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += nameTextField.getError()
        message += routingNumberTextField.getError()
        message += accountNumberTextField.getError()
        message += confirmAccountNumberTextField.getError()
    }

    
    // MARK: - Actions

    @IBAction func enrollButtonPress(_ sender: Any) {
        view.endEditing(true)
        
        FirebaseUtility.logEventV2(.autoPay(paramters: [.enroll_start]))
        FirebaseUtility.logEvent(.autoPaySubmit)
        
        LoadingView.show()
        viewModel.enroll()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] enrolled in
                LoadingView.hide()
                guard let self = self else { return }
                
                FirebaseUtility.logEventV2(.autoPay(paramters: [.enroll_complete]))
                FirebaseUtility.logEvent(.autoPayNetworkComplete)
                
                self.delegate?.autoPayViewController(self, enrolled: true)
                self.navigationController?.popViewController(animated: true)
            }, onError: { [weak self] error in
                
                FirebaseUtility.logEventV2(.autoPay(paramters: [.network_submit_error]))
                
                LoadingView.hide()
                guard let self = self,
                      let networkingError = error as? NetworkingError else { return }
                let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                                        message: networkingError.description, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            })
            .disposed(by: bag)
    }
    
    @IBAction func unenrollButtonPress(_ sender: Any) {
        view.endEditing(true)
        
        switch Configuration.shared.opco {
        case .comEd, .peco:
            performSegue(withIdentifier: "presentReasonsForStopping", sender: nil)
        case .ace, .bge, .delmarva, .pepco:
            fatalError("Opco Not Implemented: \(Configuration.shared.opco.displayString)")
        }
    }
    
    @IBAction func changeBankPress() {
        FirebaseUtility.logEventV2(.autoPay(paramters: [.modify_bank]))
    }

    func onTermsAndConditionsPress() {
        FirebaseUtility.logEventV2(.autoPay(paramters: [.terms]))
        
        let tacModal = WebViewController(title: NSLocalizedString("Terms and Conditions", comment: ""),
                                      url: URL(string: "https://webpayments.billmatrix.com/HTML/terms_conditions_en-us.html")!)
        navigationController?.present(tacModal, animated: true, completion: nil)
    }
    
    @objc
    func onLearnMorePress() {
        FirebaseUtility.logEventV2(.autoPay(paramters: [.learn_more]))

        let modalDescription = NSLocalizedString("Sign up for AutoPay and you will never have to write another check to pay your bill. With AutoPay, your payment is automatically deducted from your bank account. You will receive a monthly statement notifying you when your payment will be deducted.", comment: "")
        
        let infoModal = InfoModalViewController(title: NSLocalizedString("What is AutoPay?", comment: ""), image: UIImage(named: "img_autopaymodal")!, description: modalDescription)
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    func onRoutingNumberQuestionMarkPress() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Routing Number", comment: ""), image: #imageLiteral(resourceName: "routing_number_info"), description: NSLocalizedString("This number is used to identify your banking institution. You can find your bank’s nine-digit routing number on the bottom of your paper check.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    func onAccountNumberQuestionMarkPress() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Account Number", comment: ""), image: #imageLiteral(resourceName: "account_number_info"), description: NSLocalizedString("This number is used to identify your bank account. You can find your checking account number on the bottom of your paper check following the routing number.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
    }

}


// MARK: - TextField Delegate

extension AutoPayViewController: UITextFieldDelegate {
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


// MARK: - Change Bank Delegate

extension AutoPayViewController: AutoPayChangeBankViewControllerDelegate {
	func changedBank() {
		DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
			self.view.showToast(NSLocalizedString("AutoPay bank account updated", comment: ""))
            GoogleAnalytics.log(event: .autoPayModifyBankComplete)
		})
	}
}
