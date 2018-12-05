//
//  ReviewPaymentViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 7/3/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class ReviewPaymentViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    var viewModel: PaymentViewModel! // Passed from MakePaymentViewController

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewContentView: UIView!
    var gradientLayer = CAGradientLayer()
    
    @IBOutlet weak var activeSeveranceLabel: UILabel!
    @IBOutlet weak var overpaymentLabel: UILabel!
    
    @IBOutlet weak var paymentAccountTextLabel: UILabel!
    @IBOutlet weak var paymentAccountA11yView: UIView!
    @IBOutlet weak var paymentAccountImageView: UIImageView!
    @IBOutlet weak var paymentAccountMaskedAccountNumberLabel: UILabel!
    @IBOutlet weak var paymentAccountNicknameLabel: UILabel!
    
    // -- Receipt View -- //
    @IBOutlet weak var receiptView: UIView!
    
    @IBOutlet weak var amountDueTextLabel: UILabel!
    @IBOutlet weak var amountDueValueLabel: UILabel!
    @IBOutlet weak var dueDateTextLabel: UILabel!
    @IBOutlet weak var dueDateValueLabel: UILabel!
    
    @IBOutlet weak var convenienceFeeView: UIView!
    @IBOutlet weak var paymentAmountTextLabel: UILabel!
    @IBOutlet weak var paymentAmountValueLabel: UILabel!
    @IBOutlet weak var convenienceFeeTextLabel: UILabel!
    @IBOutlet weak var convenienceFeeValueLabel: UILabel!
    
    @IBOutlet weak var cardOverpayingView: UIView!
    @IBOutlet weak var cardOverpayingTextLabel: UILabel!
    @IBOutlet weak var cardOverpayingValueLabel: UILabel!
    
    @IBOutlet weak var bankOverpayingView: UIView!
    @IBOutlet weak var bankOverpayingTextLabel: UILabel!
    @IBOutlet weak var bankOverpayingValueLabel: UILabel!
    
    @IBOutlet weak var totalPaymentView: UIView!
    @IBOutlet weak var paymentDateTextLabel: UILabel!
    @IBOutlet weak var paymentDateValueLabel: UILabel!
    @IBOutlet weak var totalPaymentTextLabel: UILabel!
    @IBOutlet weak var totalPaymentValueLabel: UILabel!
    // ------------------ //
    
    @IBOutlet weak var termsConditionsSwitchView: UIView!
    @IBOutlet weak var termsConditionsSwitch: Switch!
    @IBOutlet weak var termsConditionsSwitchLabel: UILabel!
    @IBOutlet weak var termsConditionsButton: ButtonControl!
    @IBOutlet weak var termsConditionsButtonLabel: UILabel!
    
    @IBOutlet weak var overpayingSwitchView: UIView!
    @IBOutlet weak var overpayingSwitch: Switch!
    @IBOutlet weak var overpayingSwitchLabel: UILabel!
    
    @IBOutlet weak var activeSeveranceSwitchView: UIView!
    @IBOutlet weak var activeSeveranceSwitch: Switch!
    @IBOutlet weak var activeSeveranceSwitchLabel: UILabel!
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .softGray

        title = NSLocalizedString("Review Payment", comment: "")
        
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.rightBarButtonItem = submitButton
        viewModel.reviewPaymentSubmitButtonEnabled.drive(submitButton.rx.isEnabled).disposed(by: disposeBag)
        
        gradientLayer.frame = scrollViewContentView.bounds
        gradientLayer.colors = [
            UIColor.softGray.cgColor,
            UIColor.white.cgColor,
        ]
        scrollViewContentView.layer.insertSublayer(gradientLayer, at: 0)
        
        activeSeveranceLabel.textColor = .blackText
        activeSeveranceLabel.font = SystemFont.semibold.of(textStyle: .headline)
        activeSeveranceLabel.text = NSLocalizedString("Due to the status of this account, this payment cannot be edited or deleted once it is submitted.", comment: "")
        activeSeveranceLabel.setLineHeight(lineHeight: 24)
        
        overpaymentLabel.textColor = .blackText
        overpaymentLabel.font = SystemFont.semibold.of(textStyle: .headline)
        overpaymentLabel.text = NSLocalizedString("You are scheduling a payment that may result in overpaying your amount due.", comment: "")
        overpaymentLabel.setLineHeight(lineHeight: 24)
        
        paymentAccountTextLabel.textColor = .deepGray
        paymentAccountTextLabel.text = Environment.shared.opco == .bge ?
            NSLocalizedString("Payment Account", comment: "") : NSLocalizedString("Payment Method", comment: "")
        paymentAccountMaskedAccountNumberLabel.textColor = .blackText
        paymentAccountNicknameLabel.textColor = .middleGray
        
        receiptView.layer.cornerRadius = 10
        receiptView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        amountDueTextLabel.textColor = .deepGray
        amountDueTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountDueTextLabel.text = Environment.shared.opco == .bge ?
            NSLocalizedString("Amount Due", comment: "") : NSLocalizedString("Total Amount Due", comment: "")
        amountDueValueLabel.textColor = .deepGray
        amountDueValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        dueDateTextLabel.textColor = .deepGray
        dueDateTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        dueDateTextLabel.text = NSLocalizedString("Due Date", comment: "")
        dueDateValueLabel.textColor = .deepGray
        dueDateValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        convenienceFeeView.backgroundColor = .softGray
        paymentAmountTextLabel.textColor = .deepGray
        paymentAmountTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentAmountTextLabel.text = NSLocalizedString("Payment Amount", comment: "")
        paymentAmountValueLabel.textColor = .deepGray
        paymentAmountValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        convenienceFeeTextLabel.textColor = .deepGray
        convenienceFeeTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        convenienceFeeTextLabel.text = NSLocalizedString("Convenience Fee", comment: "")
        convenienceFeeValueLabel.textColor = .deepGray
        convenienceFeeValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        cardOverpayingTextLabel.textColor = .deepGray
        cardOverpayingTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        cardOverpayingTextLabel.text = NSLocalizedString("Overpaying", comment: "")
        cardOverpayingValueLabel.textColor = .deepGray
        cardOverpayingValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        bankOverpayingTextLabel.textColor = .deepGray
        bankOverpayingTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        bankOverpayingTextLabel.text = NSLocalizedString("Overpaying", comment: "")
        bankOverpayingValueLabel.textColor = .deepGray
        bankOverpayingValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        totalPaymentView.backgroundColor = .softGray
        paymentDateTextLabel.textColor = .blackText
        paymentDateTextLabel.font = SystemFont.medium.of(textStyle: .headline)
        paymentDateTextLabel.text = NSLocalizedString("Payment Date", comment: "")
        paymentDateValueLabel.textColor = .blackText
        paymentDateValueLabel.font = SystemFont.medium.of(textStyle: .headline)
        totalPaymentTextLabel.textColor = .blackText
        totalPaymentTextLabel.font = SystemFont.medium.of(textStyle: .headline)
        totalPaymentValueLabel.textColor = .blackText
        totalPaymentValueLabel.font = SystemFont.medium.of(textStyle: .headline)
        
        termsConditionsSwitchLabel.textColor = .deepGray
        termsConditionsSwitchLabel.font = SystemFont.regular.of(textStyle: .headline)
        if Environment.shared.opco == .bge {
            termsConditionsSwitchLabel.text = NSLocalizedString("I have read and accept the Terms and Conditions below & E-Sign Disclosure and Consent Notice. Please review and retain a copy for your records.", comment: "")
        } else {
            termsConditionsSwitchLabel.text = NSLocalizedString("Yes, I have read, understand, and agree to the terms and conditions provided below:", comment: "")
        }
        termsConditionsSwitchLabel.setLineHeight(lineHeight: 25)
        termsConditionsButtonLabel.font = SystemFont.bold.of(textStyle: .headline)
        termsConditionsButtonLabel.textColor = .actionBlue
        termsConditionsButtonLabel.text = NSLocalizedString("View terms and conditions", comment: "")
        termsConditionsSwitchLabel.isAccessibilityElement = false
        termsConditionsSwitch.accessibilityLabel = termsConditionsSwitchLabel.text!
        
        overpayingSwitchLabel.textColor = .deepGray
        overpayingSwitchLabel.font = SystemFont.regular.of(textStyle: .headline)
        overpayingSwitchLabel.text = NSLocalizedString("Yes, I acknowledge I am scheduling a payment for more than is currently due on my account.", comment: "")
        overpayingSwitchLabel.setLineHeight(lineHeight: 25)
        overpayingSwitchLabel.isAccessibilityElement = false
        overpayingSwitch.accessibilityLabel = overpayingSwitchLabel.text!
        
        activeSeveranceSwitchLabel.textColor = .deepGray
        activeSeveranceSwitchLabel.font = SystemFont.regular.of(textStyle: .headline)
        activeSeveranceSwitchLabel.text = NSLocalizedString("I acknowledge I will not be able to edit or delete this payment once submitted.", comment: "")
        activeSeveranceSwitchLabel.setLineHeight(lineHeight: 25)
        activeSeveranceSwitchLabel.isAccessibilityElement = false
        activeSeveranceSwitch.accessibilityLabel = activeSeveranceSwitchLabel.text!
        
        footerView.backgroundColor = .softGray
        footerLabel.textColor = .blackText
        footerLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        bindViewHiding()
        bindViewContent()
        bindButtonTaps()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = scrollViewContentView.bounds
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        gradientLayer.frame = scrollViewContentView.bounds
    }
    
    func bindViewHiding() {
        viewModel.isActiveSeveranceUser.map(!).drive(activeSeveranceLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOverpaying.map(!).drive(overpaymentLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOverpayingCard.map(!).drive(cardOverpayingView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOverpayingBank.map(!).drive(bankOverpayingView.rx.isHidden).disposed(by: disposeBag)
        viewModel.reviewPaymentShouldShowConvenienceFeeBox.map(!).drive(convenienceFeeView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowTermsConditionsSwitchView.map(!).drive(termsConditionsSwitchView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOverpaying.map(!).drive(overpayingSwitchView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isActiveSeveranceUser.map(!).drive(activeSeveranceSwitchView.rx.isHidden).disposed(by: disposeBag)
    }
    
    func bindViewContent() {
        // Payment Account
        viewModel.selectedWalletItemImage.drive(paymentAccountImageView.rx.image).disposed(by: disposeBag)
        viewModel.selectedWalletItemMaskedAccountString.drive(paymentAccountMaskedAccountNumberLabel.rx.text).disposed(by: disposeBag)
        viewModel.selectedWalletItemNickname.drive(paymentAccountNicknameLabel.rx.text).disposed(by: disposeBag)
        viewModel.selectedWalletItemA11yLabel.drive(paymentAccountA11yView.rx.accessibilityLabel).disposed(by: disposeBag)
        
        // Amount Due
        viewModel.amountDueCurrencyString.asDriver().drive(amountDueValueLabel.rx.text).disposed(by: disposeBag)
        
        // Due Date
        viewModel.dueDate.asDriver().drive(dueDateValueLabel.rx.text).disposed(by: disposeBag)
        
        // Payment Amount
        viewModel.paymentAmountString.asDriver().drive(paymentAmountValueLabel.rx.text).disposed(by: disposeBag)
        
        // Overpaying
        viewModel.overpayingValueDisplayString.drive(cardOverpayingValueLabel.rx.text).disposed(by: disposeBag)
        viewModel.overpayingValueDisplayString.drive(bankOverpayingValueLabel.rx.text).disposed(by: disposeBag)
        
        // Convenience Fee
        viewModel.convenienceFeeDisplayString.drive(convenienceFeeValueLabel.rx.text).disposed(by: disposeBag)
        
        // Payment Date
        viewModel.paymentDateString.asDriver().drive(paymentDateValueLabel.rx.text).disposed(by: disposeBag)
        
        // Total Payment
        viewModel.totalPaymentLabelText.drive(totalPaymentTextLabel.rx.text).disposed(by: disposeBag)
        viewModel.totalPaymentDisplayString.drive(totalPaymentValueLabel.rx.text).disposed(by: disposeBag)
        
        // Switches
        termsConditionsSwitch.rx.isOn.bind(to: viewModel.termsConditionsSwitchValue).disposed(by: disposeBag)
        overpayingSwitch.rx.isOn.bind(to: viewModel.overpayingSwitchValue).disposed(by: disposeBag)
        activeSeveranceSwitch.rx.isOn.bind(to: viewModel.activeSeveranceSwitchValue).disposed(by: disposeBag)
        
        // Footer Label
        viewModel.reviewPaymentFooterLabelText.drive(footerLabel.rx.text).disposed(by: disposeBag)
    }
    
    func bindButtonTaps() {
        termsConditionsButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            self?.onTermsConditionsPress()
        }).disposed(by: disposeBag)
    }
    
    @objc func onSubmitPress() {
        LoadingView.show()
        
        if let bankOrCard = viewModel.selectedWalletItem.value?.bankOrCard {
            switch bankOrCard {
            case .bank:
                Analytics.log(event: .eCheckSubmit)
            case .card:
                Analytics.log(event: .cardSubmit)
            }
        }
        
        let handleError = { [weak self] (errMessage: String) in
            LoadingView.hide()
            let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
            
            // use regular expression to check the US phone number format: start with 1, then -, then 3 3 4 digits grouped together that separated by dash
            // e.g: 1-111-111-1111 is valid while 1-1111111111 and 111-111-1111 are not
            if let phoneRange = errMessage.range(of:"1-\\d{3}-\\d{3}-\\d{4}", options: .regularExpression) {
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: nil))
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Contact Us", comment: ""), style: .default, handler: {
                    action -> Void in
                    UIApplication.shared.openPhoneNumberIfCan(String(errMessage[phoneRange]))
                }))
            } else {
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            }
            self?.present(alertVc, animated: true, completion: nil)
        }
        
        if viewModel.paymentId.value != nil { // Modify
            viewModel.modifyPayment(onSuccess: { [weak self] in
                LoadingView.hide()
                self?.performSegue(withIdentifier: "paymentConfirmationSegue", sender: self)
            }, onError: { errMessage in
                handleError(errMessage)
            })
        } else { // Schedule
            viewModel.schedulePayment(onDuplicate: { [weak self] (errTitle, errMessage) in
                LoadingView.hide()
                let alertVc = UIAlertController(title: errTitle, message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
                }, onSuccess: { [weak self] in
                    LoadingView.hide()
                    
                    if let bankOrCard = self?.viewModel.selectedWalletItem.value?.bankOrCard {
                        let pageView: AnalyticsEvent
                        switch bankOrCard {
                        case .bank:
                            pageView = .eCheckComplete
                        case .card:
                            pageView = .cardComplete
                        }
                        
                        Analytics.log(event: pageView)
                    }
                    
                    self?.performSegue(withIdentifier: "paymentConfirmationSegue", sender: self)
                }, onError: { [weak self] error in
                    if let bankOrCard = self?.viewModel.selectedWalletItem.value?.bankOrCard {
                        let pageView: AnalyticsEvent
                        switch bankOrCard {
                        case .bank:
                            pageView = .eCheckError
                        case .card:
                            pageView = .cardError
                        }
                        
                        Analytics.log(event: pageView,
                                      dimensions: [.errorCode: error.serviceCode])
                    }
                    handleError(error.localizedDescription)
            })
        }
    }
    
    func onTermsConditionsPress() {
        let url = Environment.shared.opco == .bge ? URL(string: "https://www.speedpay.com/terms/")! :
            URL(string:"https://webpayments.billmatrix.com/HTML/terms_conditions_en-us.html")!
        let tacModal = WebViewController(title: NSLocalizedString("Terms and Conditions", comment: ""), url: url)
        navigationController?.present(tacModal, animated: true, completion: nil)
    }
    
    func onPrivacyPolicyPress() {
        let tacModal = WebViewController(title: NSLocalizedString("Privacy Policy", comment: ""),
                                         url: URL(string:"https://webpayments.billmatrix.com/HTML/privacy_notice_en-us.html")!)
        navigationController?.present(tacModal, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PaymentConfirmationViewController {
            vc.presentingNavController = navigationController
            vc.viewModel = viewModel
        }
    }

}
