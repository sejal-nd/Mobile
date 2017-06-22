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
    func autoPayViewController(_ autoPayViewController: AutoPayViewController, enrolled: Bool)
}

class AutoPayViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var gradientView: UIView!
    var gradientLayer = CAGradientLayer()
    
    @IBOutlet weak var learnMoreButton: ButtonControl!
    @IBOutlet weak var learnMoreLabel: UILabel!
    
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
    @IBOutlet weak var tacSwitch: Switch!
    @IBOutlet weak var tacLabel: UILabel!
    @IBOutlet weak var tacButton: UIButton!
    
    // Enrolled
    @IBOutlet weak var enrolledStackView: UIStackView!
    @IBOutlet weak var enrollSwitch: Switch!
    @IBOutlet weak var enrollmentStatusLabel: UILabel!
    @IBOutlet weak var enrolledTopLabel: UILabel!
    
    @IBOutlet weak var thirdPartyLabel: UILabel!
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    weak var delegate: AutoPayViewControllerDelegate?
    
    let bag = DisposeBag()
    
    var accountDetail: AccountDetail!
    lazy var viewModel: AutoPayViewModel = { AutoPayViewModel(withAccountDetail: self.accountDetail) }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("AutoPay", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = submitButton
        
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
        bindEnrollingState()
        thirdPartyLabel.isHidden = !viewModel.shouldShowThirdPartyLabel
        thirdPartyLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        viewModel.footerText.drive(footerLabel.rx.text).addDisposableTo(bag)
        
        viewModel.canSubmit.drive(submitButton.rx.isEnabled).addDisposableTo(bag)
        
        learnMoreButton.rx.touchUpInside.asDriver()
            .drive(onNext: onLearnMorePress)
            .addDisposableTo(bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.removeFromSuperlayer()
        
        let gLayer = CAGradientLayer()
        gLayer.frame = gradientView.bounds
        gLayer.colors = [UIColor.softGray.cgColor, UIColor.white.cgColor]
        
        gradientLayer = gLayer
        gradientView.layer.addSublayer(gLayer)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        gradientLayer.frame = gradientView.bounds
    }
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    func onSubmitPress() {
        delegate?.autoPayViewController(self, enrolled: true)
        navigationController?.popViewController(animated: true)
    }
    
    private func style() {
        learnMoreButton.addShadow(color: .black, opacity: 0.12, offset: .zero, radius: 3)
        let learnMoreString = NSLocalizedString("Learn more about ", comment: "")
        let autoPayString = NSLocalizedString("AutoPay", comment: "")
        let learnMoreAboutAutoPayString = learnMoreString + "\n" + autoPayString
        let learnMoreAboutAutoPayAttrString = NSMutableAttributedString(string: learnMoreAboutAutoPayString, attributes: [NSForegroundColorAttributeName: UIColor.blackText])
        
        learnMoreAboutAutoPayAttrString.addAttribute(NSFontAttributeName,
                                                     value: OpenSans.regular.of(size: 18),
                                                     range: NSMakeRange(0, learnMoreString.characters.count))
        
        learnMoreAboutAutoPayAttrString.addAttribute(NSFontAttributeName,
                                                     value: OpenSans.bold.of(size: 18),
                                                     range: NSMakeRange(learnMoreString.characters.count + 1, autoPayString.characters.count))
        
        learnMoreLabel.attributedText = learnMoreAboutAutoPayAttrString
        
        styleNotEnrolled()
        styleEnrolled()
        
        footerLabel.font = OpenSans.regular.of(textStyle: .footnote)
        footerLabel.setLineHeight(lineHeight: 16)
    }
    
    private func styleNotEnrolled() {
        topLabel.font = OpenSans.semibold.of(textStyle: .headline)
        topLabel.setLineHeight(lineHeight: 24)
        
        tacLabel.text = NSLocalizedString("Yes, I have read, understand and agree to the terms and conditions below, and by checking this box, I authorize ComEd to regularly debit the bank account provided.\nI understand that my bank account will be automatically debited each billing period for the total amount due, that these are variable charges, and that my bill being posted in the ComEd mobile app acts as my notification.\nCustomers can see their bill monthly through the ComEd mobile app. Bills are delivered online during each billing cycle. Please note that this will not change your preferred bill delivery method.", comment: "")
        tacLabel.font = SystemFont.regular.of(textStyle: .headline)
        tacLabel.setLineHeight(lineHeight: 25)
        tacButton.titleLabel?.font = SystemFont.bold.of(textStyle: .headline)
    }
    
    private func styleEnrolled() {
        enrollmentStatusLabel.font = OpenSans.regular.of(textStyle: .headline)
        enrollmentStatusLabel.setLineHeight(lineHeight: 28)
        enrolledTopLabel.font = OpenSans.regular.of(textStyle: .body)
        enrolledTopLabel.setLineHeight(lineHeight: 16)
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
        accountNumberTextField.textField.returnKeyType = .done
    }
    
    private func bindEnrollingState() {
        
        viewModel.enrollmentStatus.asDriver().map { $0 != .enrolling }.drive(enrollStackView.rx.isHidden).addDisposableTo(bag)
        
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
            .withLatestFrom(viewModel.routingNumberErrorText)

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
    }
    
    
    func onTermsAndConditionsPress() {
        let tacModal = WebViewController(title: NSLocalizedString("Terms and Conditions", comment: ""),
                                      url: URL(string:"https://webpayments.billmatrix.com/HTML/terms_conditions_en-us.html")!)
        navigationController?.present(tacModal, animated: true, completion: nil)
    }
    
    func onLearnMorePress() {
        let modalDescription = NSLocalizedString("Sign up for AutoPay and you will never have to write another check to pay your bill. With AutoPay, your payment is automatically deducted from your bank account. You will receive a monthly statement notifying you when your payment will be deducted.", comment: "")
        
        let infoModal = InfoModalViewController(title: NSLocalizedString("What is AutoPay?", comment: ""), image: #imageLiteral(resourceName: "img_autopaymodal"), description: modalDescription)
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
    
}

extension AutoPayViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let characterSet = CharacterSet(charactersIn: string)
        if textField == routingNumberTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 9
        } else if textField == accountNumberTextField.textField || textField == confirmAccountNumberTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet)
        }
        return true
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        if textField == routingNumberTextField.textField && textField.text?.characters.count == 9 {
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

