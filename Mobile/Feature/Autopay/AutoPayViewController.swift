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
    @IBOutlet weak var checkingSavingsSegmentedControl: SegmentedControlNew!
    @IBOutlet weak var nameTextField: FloatLabelTextFieldNew!
    @IBOutlet weak var routingNumberTextField: FloatLabelTextFieldNew!
    @IBOutlet weak var routingNumberTooltipButton: UIButton!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextFieldNew!
    @IBOutlet weak var accountNumberTooltipButton: UIButton!
    @IBOutlet weak var confirmAccountNumberTextField: FloatLabelTextFieldNew!
    
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
    @IBOutlet weak var enrollButton: PrimaryButtonNew!
    @IBOutlet weak var unenrollView: UIView!
    @IBOutlet weak var unenrollButtonLabel: UILabel!
    @IBOutlet weak var unenrollButton: UIButton!
    
    // Prevents status bar color flash when pushed
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    weak var delegate: AutoPayViewControllerDelegate?
    
    let bag = DisposeBag()
    
    var accountDetail: AccountDetail!

    lazy var viewModel: AutoPayViewModel = { AutoPayViewModel(withPaymentService: ServiceFactory.createPaymentService(), walletService: ServiceFactory.createWalletService(), accountDetail: self.accountDetail) }()

    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        style()
        configureView()
        textFieldSetup()
        bindEnrollingState()
        bindEnrolledState()
        
    viewModel.footerText.drive(footerLabel.rx.text).disposed(by: bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AutoPayChangeBankViewController {
            vc.viewModel = viewModel
            vc.delegate = self
        } else if let nav = segue.destination as? LargeTitleNavigationController, let vc = nav.viewControllers.first as? AutoPayReasonsForStoppingViewController {
            vc.viewModel = viewModel
            vc.delegate = delegate
            vc.parentVc = self
        }
    }
    
    
    // MARK: - Helper
    
    private func configureView() {
        title = NSLocalizedString("AutoPay", comment: "")
        
        let helpButton = UIBarButtonItem(image: UIImage(named: "ic_tooltip"), style: .plain, target: self, action: #selector(onLearnMorePress))
        navigationItem.rightBarButtonItem = helpButton
        
    viewModel.canSubmit.drive(enrollButton.rx.isEnabled).disposed(by: bag)
        
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
            enrolledTopLabel.font = SystemFont.regular.of(textStyle: .body)
            enrolledTopLabel.setLineHeight(lineHeight: 16)
            
            unenrollButtonLabel.textColor = .deepGray
            unenrollButtonLabel.font = SystemFont.regular.of(textStyle: .subheadline)
            
            unenrollButton.titleLabel?.font = SystemFont.bold.of(textStyle: .subheadline)
        } else {
            // Not enrolled
            topLabel.textColor = .deepGray
            topLabel.font = SystemFont.regular.of(textStyle: .body)
            topLabel.setLineHeight(lineHeight: 24)
            
            tacLabel.text = viewModel.tacLabelText
            tacLabel.font = SystemFont.regular.of(textStyle: .subheadline)
            tacLabel.setLineHeight(lineHeight: 25)
            tacSwitch.accessibilityLabel = viewModel.tacSwitchAccessibilityLabel
            tacButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .subheadline)
            GoogleAnalytics.log(event: .autoPayEnrollOffer)
        }

        footerLabel.font = SystemFont.regular.of(textStyle: .caption1)
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
    
    private func bindEnrolledState() {
        viewModel.enrollmentStatus.asDriver().map { $0 == .enrolling }.drive(enrolledStackView.rx.isHidden).disposed(by: bag)
    }
    
    private func bindEnrollingState() {
        viewModel.enrollmentStatus.asDriver().map { $0 != .enrolling }.drive(enrollStackView.rx.isHidden).disposed(by: bag)
        
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
        LoadingView.show()
        viewModel.submit()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] enrolled in
                    LoadingView.hide()
                    guard let self = self else { return }
                    self.delegate?.autoPayViewController(self, enrolled: true)
                    self.navigationController?.popViewController(animated: true)
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
    
    
    @IBAction func unenrollButtonPesss(_ sender: Any) {
        onSubmitPress()
    }
    
    @objc func onSubmitPress() {
        view.endEditing(true)
        guard Environment.shared.opco == .comEd else { fatalError("Opco Not Implemented: \(Environment.shared.opco)") }
        
        performSegue(withIdentifier: "presentReasonsForStopping", sender: nil)
    }

    func onTermsAndConditionsPress() {
        let tacModal = WebViewController(title: NSLocalizedString("Terms and Conditions", comment: ""),
                                      url: URL(string: "https://webpayments.billmatrix.com/HTML/terms_conditions_en-us.html")!)
        navigationController?.present(tacModal, animated: true, completion: nil)
    }
    
    @objc
    func onLearnMorePress() {
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
