//
//  UnauthenticatedOutageValidateAccountViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 9/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class UnauthenticatedOutageValidateAccountViewController: KeyboardAvoidingStickyFooterViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var maintenanceModeView: MaintenanceModeView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextField!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var accountNumberTooltipButton: UIButton!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerTextView: ZeroInsetDataDetectorTextView!
    
    @IBOutlet weak var stickyFooterView: StickyFooterView!
    @IBOutlet weak var continueButton: PrimaryButton!
    
    var analyticsSource: AnalyticsOutageSource!
    
    let viewModel = UnauthenticatedOutageViewModel()

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Outage", comment: "")
        
        headerLabel.textColor = .deepGray
        headerLabel.font = SystemFont.regular.of(textStyle: .headline)
        headerLabel.text = NSLocalizedString("Please help us validate your account.", comment: "")
        
        phoneNumberTextField.placeholder = Environment.shared.opco.isPHI ? NSLocalizedString("Phone Number*", comment: "") : NSLocalizedString("Primary Phone Number*", comment: "")
        phoneNumberTextField.textField.autocorrectionType = .no
        phoneNumberTextField.setKeyboardType(.phonePad, doneActionTarget: self, doneActionSelector: #selector(onKeyboardDonePress))
        phoneNumberTextField.textField.delegate = self
        
        accountNumberTextField.placeholder = NSLocalizedString("Account Number*", comment: "")
        accountNumberTextField.textField.autocorrectionType = .no
        accountNumberTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(onKeyboardDonePress))
        accountNumberTextField.textField.delegate = self
        accountNumberTextField.textField.isShowingAccessory = true
        accountNumberTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        footerView.addTopBorder(color: .accentGray, width: 1)
        footerTextView.textColor = .deepGray
        footerTextView.tintColor = .actionBlue // For the phone numbers
        footerTextView.linkTapDelegate = self
        
        maintenanceModeView.isHidden = true
        
        bindViewModel()
        bindValidation()
        
        checkForMaintenance()
        
        maintenanceModeView.reload
            .subscribe(onNext: { [weak self] in
                self?.checkForMaintenance()
            })
            .disposed(by: disposeBag)
    }
    
    func checkForMaintenance() {
        loadingIndicator.isHidden = false
        maintenanceModeView.isHidden = true
        scrollView.isHidden = true
        stickyFooterView.isHidden = true
        navigationItem.rightBarButtonItem = nil
        
        viewModel.checkForMaintenance(
            onOutageOnly: { [weak self] _ in
                self?.loadingIndicator.isHidden = true
                self?.maintenanceModeView.isHidden = false
                self?.scrollView.isHidden = true
                self?.stickyFooterView.isHidden = true
            }, onNeither: { [weak self] in
                self?.loadingIndicator.isHidden = true
                self?.maintenanceModeView.isHidden = true
                self?.scrollView.isHidden = false
                self?.stickyFooterView.isHidden = false
            })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func bindViewModel() {
        phoneNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneNumber).disposed(by: disposeBag)
        viewModel.phoneNumberTextFieldEnabled.drive(phoneNumberTextField.rx.isEnabled).disposed(by: disposeBag)
        
        accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).disposed(by: disposeBag)
        viewModel.accountNumberTextFieldEnabled.drive(accountNumberTextField.rx.isEnabled).disposed(by: disposeBag)
        viewModel.accountNumberTextFieldEnabled.not().drive(accountNumberTooltipButton.rx.isHidden).disposed(by: disposeBag)
        
        footerTextView.attributedText = viewModel.footerTextViewText
    }
    
    func bindValidation() {
        viewModel.continueButtonEnabled.drive(continueButton.rx.isEnabled).disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.phoneNumber.asDriver(), viewModel.phoneNumberHasTenDigits))
            .filter { !$0.0.isEmpty }
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                if !$1 {
                    self.phoneNumberTextField.setError(NSLocalizedString("Phone number must be 10 digits long.", comment: ""))
                }
                self.accessibilityErrorLabel()
            })
            .disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] _ in
            self?.phoneNumberTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.accountNumber.asDriver(), viewModel.accountNumberHasValidlength))
            .filter { !$0.0.isEmpty }
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                if !$1 {
                    let errorMessage = NSLocalizedString("Account number must be \(Environment.shared.opco.isPHI ? 11 : 10) digits long.", comment: "")
                    self.accountNumberTextField.setError(errorMessage)
                }
                self.accessibilityErrorLabel()
            })
            .disposed(by: disposeBag)
        
        accountNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] _ in
            self?.accountNumberTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += phoneNumberTextField.getError()
        message += accountNumberTextField.getError()
        
        if message.isEmpty {
            continueButton.accessibilityLabel = NSLocalizedString("Continue", comment: "")
        } else {
            continueButton.accessibilityLabel = String(format: NSLocalizedString("%@ Continue", comment: ""), message)
        }
    }
    
    @objc func onKeyboardDonePress() {
        viewModel.continueButtonEnabled.asObservable()
            .take(1)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] enabled in
                if enabled {
                    self?.onContinuePress()
                } else {
                    self?.view.endEditing(true)
                }
            }).disposed(by: disposeBag)
    }
    
    @IBAction func onContinuePress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.fetchOutageStatus(onSuccess: { [weak self] in
            guard let self = self else { return }
            LoadingView.hide()
            
            if self.viewModel.selectedOutageStatus.value != nil {
                self.performSegue(withIdentifier: "presentOutage", sender: self)
            } else {
                self.performSegue(withIdentifier: "outageValidateAccountResultSegue", sender: self)
            }
        }, onError: { [weak self] errTitle, errMessage in
            guard let self = self else { return }
            LoadingView.hide()
            
            let alertVc = UIAlertController(title: errTitle, message: errMessage, preferredStyle: .alert)
            
            if errTitle == NSLocalizedString("Cut for non pay", comment: "") {
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: nil))
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Pay Bill", comment: ""), style: .default, handler: { [weak self] _ in
                    let storyboard = UIStoryboard(name: "Login", bundle: nil)
                    let landingVC = storyboard.instantiateViewController(withIdentifier: "landingViewController")
                    let loginVC = storyboard.instantiateViewController(withIdentifier: "loginViewController")
                    self?.navigationController?.setViewControllers([landingVC, loginVC], animated: false)
                }))
            } else if let phoneRange = errMessage.range(of:"1-\\d{3}-\\d{3}-\\d{4}", options: .regularExpression) {
                // use regular expression to check the US phone number format: start with 1, then -, then 3 3 4 digits grouped together that separated by dash
                // e.g: 1-111-111-1111 is valid while 1-1111111111 and 111-111-1111 are not
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: nil))
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Contact Us", comment: ""), style: .default, handler: { _ in
                    UIApplication.shared.openPhoneNumberIfCan(String(errMessage[phoneRange]))
                }))
            } else if let phoneRange = errMessage.range(of:"d{3}-\\d{3}-\\d{4}", options: .regularExpression) {
                // use regular expression to check the US phone number format: start with 3 then 3 4 digits grouped together that separated by dash
                // e.g: 202-833-7500 is valid while 1-1111111111 and 1-111-111-1111 are not
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: nil))
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Contact Us", comment: ""), style: .default, handler: { _ in
                    UIApplication.shared.openPhoneNumberIfCan(String(errMessage[phoneRange]))
                }))
            } else {
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            }
            
            self.present(alertVc, animated: true, completion: nil)
        })
        
        switch analyticsSource {
        case .report?:
            GoogleAnalytics.log(event: .reportAnOutageUnAuthSubmitAcctVal)
        case .status?:
            GoogleAnalytics.log(event: .outageStatusUnAuthAcctValidate)
        default:
            break
        }
    }
    
    @IBAction func onAccountNumberTooltipPress() {
        FirebaseUtility.logEvent(.unauthOutage, parameters: [EventParameter(parameterName: .action, value: .account_number_help)])
        
        let description: String
        switch Environment.shared.opco {
        case .bge:
            description = NSLocalizedString("Your Customer Account Number can be found in the lower right portion of your bill. Please enter 10-digits including leading zeros.", comment: "")
        case .comEd:
            description = NSLocalizedString("Your Account Number is located in the upper right portion of a residential bill and the upper center portion of a commercial bill. Please enter all 10 digits, including leading zeros, but no dashes.", comment: "")
        case .peco:
            description = NSLocalizedString("Your Account Number is located in the upper left portion of your bill. Please enter all 10 digits, including leading zeroes, but no dashes. If \"SUMM\" appears after your name on your bill, please enter any account from your list of individual accounts.", comment: "")
        case .ace, .delmarva, .pepco:
            description = NSLocalizedString("Your Account Number is located in the upper-left portion of your bill. Please enter all 11 digits, but no spaces", comment: "")
        }
        let infoModal = InfoModalViewController(title: NSLocalizedString("Find Account Number", comment: ""), image: #imageLiteral(resourceName: "bill_infographic"), description: description)
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UnauthenticatedOutageValidateAccountResultViewController {
            vc.viewModel = viewModel
            vc.analyticsSource = analyticsSource
        } else if let vc = segue.destination as? OutageViewController {
            vc.userState = .unauthenticated
            vc.viewModel.outageStatus = viewModel.selectedOutageStatus.value
            vc.viewModel.accountNumber = viewModel.selectedOutageStatus.value?.accountNumber
        }
    }

}

extension UnauthenticatedOutageValidateAccountViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == phoneNumberTextField.textField {
            let components = newString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            
            let decimalString = components.joined(separator: "") as NSString
            let length = decimalString.length
            
            if length > 10 {
                return false
            }
            
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if length - index > 3 {
                let areaCode = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("(%@) ", areaCode)
                index += 3
            }
            if length - index > 3 {
                let prefix = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substring(from: index)
            formattedString.append(remainder)
            textField.text = formattedString as String
            
            textField.sendActions(for: .valueChanged) // Send rx events
            
            return false
        } else if textField == accountNumberTextField.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= (Environment.shared.opco.isPHI ? 11 : 10)
        }
        
        return true
    }
    
}

extension UnauthenticatedOutageValidateAccountViewController: DataDetectorTextViewLinkTapDelegate {
    
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL) {
        GoogleAnalytics.log(event: .outageStatusUnAuthAcctValEmergencyPhone)
    }
}
