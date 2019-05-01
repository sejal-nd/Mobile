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
    @IBOutlet weak var gradientView: UIView!
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
        
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress(submitButton:)))
        navigationItem.rightBarButtonItem = submitButton
        viewModel.reviewPaymentSubmitButtonEnabled.drive(submitButton.rx.isEnabled).disposed(by: disposeBag)
        
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor.softGray.cgColor,
            UIColor.white.cgColor,
        ]

        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        
        activeSeveranceLabel.textColor = .blackText
        activeSeveranceLabel.font = SystemFont.semibold.of(textStyle: .headline)
        activeSeveranceLabel.text = NSLocalizedString("Due to the status of this account, this payment cannot be edited or deleted once it is submitted.", comment: "")
        activeSeveranceLabel.setLineHeight(lineHeight: 24)
        
        overpaymentLabel.textColor = .blackText
        overpaymentLabel.font = SystemFont.semibold.of(textStyle: .headline)
        overpaymentLabel.text = NSLocalizedString("You are scheduling a payment that may result in overpaying your total amount due.", comment: "")
        overpaymentLabel.setLineHeight(lineHeight: 24)
        
        paymentAccountTextLabel.textColor = .deepGray
        paymentAccountTextLabel.text = NSLocalizedString("Payment Method", comment: "")
        paymentAccountMaskedAccountNumberLabel.textColor = .blackText
        paymentAccountNicknameLabel.textColor = .middleGray
        
        receiptView.layer.cornerRadius = 10
        receiptView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        amountDueTextLabel.textColor = .deepGray
        amountDueTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountDueTextLabel.text = NSLocalizedString("Total Amount Due", comment: "")
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
        termsConditionsSwitchLabel.text = NSLocalizedString("Yes, I have read, understand, and agree to the terms and conditions provided below:", comment: "")
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
        footerLabel.text = viewModel.reviewPaymentFooterLabelText
        
        bindViewHiding()
        bindViewContent()
        bindButtonTaps()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = gradientView.bounds
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        gradientLayer.frame = gradientView.bounds
    }
    
    func bindViewHiding() {
        viewModel.isActiveSeveranceUser.map(!).drive(activeSeveranceLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOverpaying.map(!).drive(overpaymentLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOverpayingCard.map(!).drive(cardOverpayingView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOverpayingBank.map(!).drive(bankOverpayingView.rx.isHidden).disposed(by: disposeBag)
        viewModel.reviewPaymentShouldShowConvenienceFeeBox.map(!).drive(convenienceFeeView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOverpaying.map(!).drive(overpayingSwitchView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isActiveSeveranceUser.map(!).drive(activeSeveranceSwitchView.rx.isHidden).disposed(by: disposeBag)
    }
    
    func bindViewContent() {
        // Payment Method
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
        convenienceFeeValueLabel.text = viewModel.convenienceFee.currencyString
        
        // Payment Date
        viewModel.paymentDateString.asDriver().drive(paymentDateValueLabel.rx.text).disposed(by: disposeBag)
        
        // Total Payment
        viewModel.totalPaymentLabelText.drive(totalPaymentTextLabel.rx.text).disposed(by: disposeBag)
        viewModel.totalPaymentDisplayString.drive(totalPaymentValueLabel.rx.text).disposed(by: disposeBag)
        
        // Switches
        termsConditionsSwitch.rx.isOn.bind(to: viewModel.termsConditionsSwitchValue).disposed(by: disposeBag)
        overpayingSwitch.rx.isOn.bind(to: viewModel.overpayingSwitchValue).disposed(by: disposeBag)
        activeSeveranceSwitch.rx.isOn.bind(to: viewModel.activeSeveranceSwitchValue).disposed(by: disposeBag)
    }
    
    func bindButtonTaps() {
        termsConditionsButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            self?.onTermsConditionsPress()
        }).disposed(by: disposeBag)
    }
    
    @objc func onSubmitPress(submitButton: UIBarButtonItem) {
        guard submitButton.isEnabled else { return }
        
        LoadingView.show()
        
        if let bankOrCard = viewModel.selectedWalletItem.value?.bankOrCard, let temp = viewModel.selectedWalletItem.value?.isTemporary {
            switch bankOrCard {
            case .bank:
                Analytics.log(event: .eCheckSubmit, dimensions: [.paymentTempWalletItem: temp ? "true" : "false"])
            case .card:
                Analytics.log(event: .cardSubmit, dimensions: [.paymentTempWalletItem: temp ? "true" : "false"])
            }
        }
        
        let handleError = { [weak self] (err: ServiceError) in
            guard let self = self else { return }
            
            LoadingView.hide()
            let paymentusAlertVC = UIAlertController.paymentusErrorAlertController(
                forError: err,
                walletItem: self.viewModel.selectedWalletItem.value!,
                okHandler: { [weak self] _ in
                    guard let self = self else { return }
                    if err.serviceCode == ServiceErrorCode.walletItemIdTimeout.rawValue {
                        guard let navCtl = self.navigationController else { return }
                        let makePaymentVC = UIStoryboard(name: "Payment", bundle: nil)
                            .instantiateInitialViewController() as! MakePaymentViewController
                        makePaymentVC.accountDetail = self.viewModel.accountDetail.value
                        navCtl.viewControllers = [navCtl.viewControllers.first!, makePaymentVC]
                    }
                },
                callHandler: { _ in
                    UIApplication.shared.openPhoneNumberIfCan(self.viewModel.errorPhoneNumber)
                }
            )
            self.present(paymentusAlertVC, animated: true, completion: nil)
        }
        
        if viewModel.paymentId.value != nil { // Modify
            viewModel.modifyPayment(onSuccess: { [weak self] in
                LoadingView.hide()
                self?.performSegue(withIdentifier: "paymentConfirmationSegue", sender: self)
            }, onError: { error in
                handleError(error)
            })
        } else { // Schedule
            viewModel.schedulePayment(onDuplicate: { [weak self] (errTitle, errMessage) in
                LoadingView.hide()
                let alertVc = UIAlertController(title: errTitle, message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
                }, onSuccess: { [weak self] in
                    LoadingView.hide()
                    if let bankOrCard = self?.viewModel.selectedWalletItem.value?.bankOrCard, let temp = self?.viewModel.selectedWalletItem.value?.isTemporary {
                        switch bankOrCard {
                        case .bank:
                            Analytics.log(event: .eCheckComplete, dimensions: [.paymentTempWalletItem: temp ? "true" : "false"])
                        case .card:
                            Analytics.log(event: .cardComplete, dimensions: [.paymentTempWalletItem: temp ? "true" : "false"])
                        }
                    }
                    
                    self?.performSegue(withIdentifier: "paymentConfirmationSegue", sender: self)
                }, onError: { [weak self] error in
                    if let bankOrCard = self?.viewModel.selectedWalletItem.value?.bankOrCard, let temp = self?.viewModel.selectedWalletItem.value?.isTemporary {
                        switch bankOrCard {
                        case .bank:
                            Analytics.log(event: .eCheckError, dimensions: [
                                .errorCode: error.serviceCode,
                                .paymentTempWalletItem: temp ? "true" : "false"
                                ])
                        case .card:
                            Analytics.log(event: .cardError, dimensions: [
                                .errorCode: error.serviceCode,
                                .paymentTempWalletItem: temp ? "true" : "false"
                                ])
                        }
                    }
                    
                    handleError(error)
            })
        }
    }
    
    func onTermsConditionsPress() {
        let url = URL(string: "https://ipn2.paymentus.com/rotp/www/terms-and-conditions.html")!
        let tacModal = WebViewController(title: NSLocalizedString("Terms and Conditions", comment: ""), url: url)
        navigationController?.present(tacModal, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PaymentConfirmationViewController {
            vc.presentingNavController = navigationController
            vc.viewModel = viewModel
        }
    }

}
