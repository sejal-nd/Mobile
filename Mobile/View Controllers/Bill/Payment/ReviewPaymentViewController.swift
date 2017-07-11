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
    
    @IBOutlet weak var overpaymentLabel: UILabel!
    
    @IBOutlet weak var paymentAccountTextLabel: UILabel!
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
    
    @IBOutlet weak var overpayingView: UIView!
    @IBOutlet weak var overpayingTextLabel: UILabel!
    @IBOutlet weak var overpayingValueLabel: UILabel!
    
    @IBOutlet weak var totalPaymentView: UIView!
    @IBOutlet weak var paymentDateTextLabel: UILabel!
    @IBOutlet weak var paymentDateValueLabel: UILabel!
    @IBOutlet weak var totalPaymentTextLabel: UILabel!
    @IBOutlet weak var totalPaymentValueLabel: UILabel!
    // ------------------ //
    
    @IBOutlet weak var termsConditionsSwitchView: UIView!
    @IBOutlet weak var termsConditionsSwitch: Switch!
    @IBOutlet weak var termsConditionsSwitchLabel: UILabel!
    @IBOutlet weak var termsConditionsButtonView: UIView!
    @IBOutlet weak var termsConditionsButton: UIButton!
    
    @IBOutlet weak var overpayingSwitchView: UIView!
    @IBOutlet weak var overpayingSwitch: Switch!
    @IBOutlet weak var overpayingSwitchLabel: UILabel!
    
    @IBOutlet weak var billMatrixView: UIView!
    @IBOutlet weak var privacyPolicyButton: UIButton!
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .softGray

        title = NSLocalizedString("Review Payment", comment: "")
        
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.rightBarButtonItem = submitButton
        viewModel.reviewPaymentSubmitButtonEnabled.drive(submitButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        gradientLayer.frame = scrollViewContentView.bounds
        gradientLayer.colors = [
            UIColor.softGray.cgColor,
            UIColor.white.cgColor,
        ]
        scrollViewContentView.layer.insertSublayer(gradientLayer, at: 0)
        
        overpaymentLabel.textColor = .blackText
        overpaymentLabel.font = SystemFont.semibold.of(textStyle: .headline)
        overpaymentLabel.text = NSLocalizedString("You are scheduling a payment that may result in overpaying your amount due.", comment: "")
        overpaymentLabel.setLineHeight(lineHeight: 24)
        
        paymentAccountTextLabel.textColor = .deepGray
        paymentAccountTextLabel.text = NSLocalizedString("Payment Account", comment: "")
        paymentAccountMaskedAccountNumberLabel.textColor = .blackText
        paymentAccountNicknameLabel.textColor = .middleGray
        
        receiptView.addShadow(color: .black, opacity: 0.1, offset: CGSize(width: 0, height: 0), radius: 2)
        
        amountDueTextLabel.textColor = .deepGray
        amountDueTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountDueTextLabel.text = NSLocalizedString("Amount Due", comment: "")
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
        
        overpayingTextLabel.textColor = .deepGray
        overpayingTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        overpayingTextLabel.text = NSLocalizedString("Overpaying", comment: "")
        overpayingValueLabel.textColor = .deepGray
        overpayingValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        totalPaymentView.backgroundColor = .softGray
        paymentDateTextLabel.textColor = .blackText
        paymentDateTextLabel.font = SystemFont.medium.of(textStyle: .headline)
        paymentDateTextLabel.text = NSLocalizedString("Payment Date", comment: "")
        paymentDateValueLabel.textColor = .blackText
        paymentDateValueLabel.font = SystemFont.medium.of(textStyle: .headline)
        totalPaymentTextLabel.textColor = .blackText
        totalPaymentTextLabel.font = SystemFont.medium.of(textStyle: .headline)
        totalPaymentTextLabel.text = NSLocalizedString("Total Payment", comment: "")
        totalPaymentValueLabel.textColor = .blackText
        totalPaymentValueLabel.font = SystemFont.medium.of(textStyle: .headline)
        
        termsConditionsSwitchLabel.textColor = .deepGray
        termsConditionsSwitchLabel.font = SystemFont.regular.of(textStyle: .headline)
        termsConditionsSwitchLabel.text = NSLocalizedString("Yes, I have read, understand, and agree to the terms and conditions provided below:", comment: "")
        termsConditionsSwitchLabel.setLineHeight(lineHeight: 25)
        termsConditionsButton.setTitleColor(.actionBlue, for: .normal)
        termsConditionsButton.setTitle(NSLocalizedString("View terms and conditions", comment: ""), for: .normal)
        termsConditionsButton.titleLabel?.font = SystemFont.bold.of(textStyle: .headline)
        
        overpayingSwitchLabel.textColor = .deepGray
        overpayingSwitchLabel.font = SystemFont.regular.of(textStyle: .headline)
        overpayingSwitchLabel.text = NSLocalizedString("Yes, I acknowledge I am scheduling a payment for more than is currently due on my account.", comment: "")
        overpayingSwitchLabel.setLineHeight(lineHeight: 25)
        
        privacyPolicyButton.setTitleColor(.actionBlue, for: .normal)
        privacyPolicyButton.setTitle(NSLocalizedString("Privacy Policy", comment: ""), for: .normal)
        
        footerView.backgroundColor = .softGray
        footerLabel.textColor = .blackText
        footerLabel.text = NSLocalizedString("You will receive an email confirming that your payment was submitted successfully. If you receive an error message, please check for your email confirmation to verify you’ve successfully submitted payment.", comment: "")
        
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
        viewModel.isOverpaying.map(!).drive(overpaymentLabel.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.isOverpaying.map(!).drive(overpayingView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.reviewPaymentShouldShowConvenienceFeeBox.map(!).drive(convenienceFeeView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowTermsConditionsSwitchView.map(!).drive(termsConditionsSwitchView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.isOverpaying.map(!).drive(overpayingSwitchView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowBillMatrixView.map(!).drive(billMatrixView.rx.isHidden).addDisposableTo(disposeBag)
    }
    
    func bindViewContent() {
        // Payment Account
        viewModel.selectedWalletItemImage.drive(paymentAccountImageView.rx.image).addDisposableTo(disposeBag)
        viewModel.selectedWalletItemMaskedAccountString.drive(paymentAccountMaskedAccountNumberLabel.rx.text).addDisposableTo(disposeBag)
        viewModel.selectedWalletItemNickname.drive(paymentAccountNicknameLabel.rx.text).addDisposableTo(disposeBag)
        
        // Amount Due
        viewModel.amountDueCurrencyString.asDriver().drive(amountDueValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Due Date
        viewModel.dueDate.asDriver().drive(dueDateValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Payment Amount
        viewModel.paymentAmountDisplayString.asDriver().drive(paymentAmountValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Overpaying
        viewModel.overpayingValueDisplayString.drive(overpayingValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Convenience Fee
        viewModel.convenienceFeeDisplayString.drive(convenienceFeeValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Payment Date
        viewModel.paymentDateString.asDriver().drive(paymentDateValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Total Payment
        viewModel.totalPaymentDisplayString.asDriver().drive(totalPaymentValueLabel.rx.text).addDisposableTo(disposeBag)
        
        termsConditionsSwitch.rx.isOn.bind(to: viewModel.termsConditionsSwitchValue).addDisposableTo(disposeBag)
        overpayingSwitch.rx.isOn.bind(to: viewModel.overpayingSwitchValue).addDisposableTo(disposeBag)
    }
    
    func bindButtonTaps() {
        termsConditionsButton.rx.touchUpInside.asDriver().drive(onNext: onTermsConditionsPress).addDisposableTo(disposeBag)
        privacyPolicyButton.rx.touchUpInside.asDriver().drive(onNext: onPrivacyPolicyPress).addDisposableTo(disposeBag)
    }
    
    func onSubmitPress() {
        LoadingView.show()
        viewModel.schedulePayment(onSuccess: {
            LoadingView.hide()
            self.performSegue(withIdentifier: "paymentConfirmationSegue", sender: self)
        }, onError: { err in
            LoadingView.hide()
            let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: err.text, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alertVc, animated: true, completion: nil)
        })
    }
    
    func onTermsConditionsPress() {
        let url = Environment.sharedInstance.opco == .bge ? URL(string: "https://www.speedpay.com/westernuniontac_cf.asp")! :
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
            vc.presentingNavController = self.navigationController!
            vc.viewModel = viewModel
        }
    }

}
