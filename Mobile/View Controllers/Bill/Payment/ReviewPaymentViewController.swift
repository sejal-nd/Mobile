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
    
    @IBOutlet weak var overpaymentView: UIView!
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
    
    @IBOutlet weak var totalPaymentView: UIView!
    @IBOutlet weak var paymentDateTextLabel: UILabel!
    @IBOutlet weak var paymentDateValueLabel: UILabel!
    @IBOutlet weak var totalPaymentTextLabel: UILabel!
    @IBOutlet weak var totalPaymentValueLabel: UILabel!
    // ------------------ //
    
    @IBOutlet weak var reviewSwitchView: UIView!
    @IBOutlet weak var reviewSwitch: Switch!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var termsConditionsButtonView: UIView!
    @IBOutlet weak var termsConditionsButton: UIButton!
    
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
        
        reviewLabel.textColor = .deepGray
        reviewLabel.font = SystemFont.regular.of(textStyle: .headline)
        reviewLabel.text = viewModel.switchViewLabelText
        reviewLabel.setLineHeight(lineHeight: 25)
        termsConditionsButton.setTitleColor(.actionBlue, for: .normal)
        termsConditionsButton.setTitle(NSLocalizedString("View terms and conditions", comment: ""), for: .normal)
        termsConditionsButton.titleLabel?.font = SystemFont.bold.of(textStyle: .headline)
        
        privacyPolicyButton.setTitleColor(.actionBlue, for: .normal)
        privacyPolicyButton.setTitle(NSLocalizedString("Privacy Policy", comment: ""), for: .normal)
        
        footerView.backgroundColor = .softGray
        footerLabel.textColor = .blackText
        footerLabel.text = NSLocalizedString("You will receive an email confirming that your payment was submitted successfully. If you receive an error message, please check for your email confirmation to verify you’ve successfully submitted payment.", comment: "")
        
        bindViewHiding()
        bindViewContent()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = scrollViewContentView.bounds
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        gradientLayer.frame = scrollViewContentView.bounds
    }
    
    func bindViewHiding() {
        viewModel.shouldShowOverpaymentLabel.map(!).drive(overpaymentView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.reviewPaymentShouldShowConvenienceFeeBox.map(!).drive(convenienceFeeView.rx.isHidden).addDisposableTo(disposeBag)
        
        viewModel.shouldShowSwitchView.map(!).drive(reviewSwitchView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowTermsConditionsButton.map(!).drive(termsConditionsButtonView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowBillMatrixView.map(!).drive(billMatrixView.rx.isHidden).addDisposableTo(disposeBag)
    }
    
    func bindViewContent() {
        // Payment Account
        viewModel.selectedWalletItemImage.drive(paymentAccountImageView.rx.image).addDisposableTo(disposeBag)
        viewModel.selectedWalletItemMaskedAccountString.drive(paymentAccountMaskedAccountNumberLabel.rx.text).addDisposableTo(disposeBag)
        viewModel.selectedWalletItemNickname.drive(paymentAccountNicknameLabel.rx.text).addDisposableTo(disposeBag)
        
        // Amount Due
        viewModel.amountDueValue.asDriver().drive(amountDueValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Due Date
        viewModel.dueDate.asDriver().drive(dueDateValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Payment Amount
        viewModel.paymentAmountDisplayString.asDriver().drive(paymentAmountValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Convenience Fee
        viewModel.convenienceFeeDisplayString.asDriver().drive(convenienceFeeValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Payment Date
        viewModel.fixedPaymentDateString.asDriver().drive(paymentDateValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Total Payment
        viewModel.totalPaymentDisplayString.asDriver().drive(totalPaymentValueLabel.rx.text).addDisposableTo(disposeBag)
        
        reviewSwitch.rx.isOn.bind(to: viewModel.reviewPaymentSwitchValue).addDisposableTo(disposeBag)
    }
    
    func onSubmitPress() {
        performSegue(withIdentifier: "paymentConfirmationSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PaymentConfirmationViewController {
            vc.presentingNavController = self.navigationController!
        }
    }

}
