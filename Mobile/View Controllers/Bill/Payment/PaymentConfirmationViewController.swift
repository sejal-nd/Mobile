//
//  PaymentConfirmationViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 7/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class PaymentConfirmationViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var navBarTitleLabel: UILabel!
    @IBOutlet weak var confirmationLabel: UILabel!

    @IBOutlet weak var paymentInfoView: UIView!
    @IBOutlet weak var paymentDateTextLabel: UILabel!
    @IBOutlet weak var paymentDateValueLabel: UILabel!
    @IBOutlet weak var amountPaidTextLabel: UILabel!
    @IBOutlet weak var amountPaidValueLabel: UILabel!
    @IBOutlet weak var convenienceFeeLabel: UILabel!
    
    @IBOutlet weak var autoPayView: UIView!
    @IBOutlet weak var autoPayLabel: UILabel!
    @IBOutlet weak var enrollAutoPayButton: SecondaryButton!
    
    @IBOutlet weak var billMatrixView: UIView!
    @IBOutlet weak var privacyPolicyButton: UIButton!
    
    var presentingNavController: UINavigationController! // Passed from ReviewPaymentViewController
    
    var viewModel: PaymentViewModel! // Passed from ReviewPaymentViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        xButton.tintColor = .actionBlue
        xButton.accessibilityLabel = NSLocalizedString("Close", comment: "")

        navBarTitleLabel.textColor = .blackText
        navBarTitleLabel.text = NSLocalizedString("Payment Confirmation", comment: "")
        
        confirmationLabel.textColor = .blackText
        confirmationLabel.font = OpenSans.regular.of(textStyle: .body)
        var confirmationMessage = ""
        if viewModel.paymentId.value != nil {
            confirmationMessage += NSLocalizedString("Thank you for modifying your payment.", comment: "")
        } else {
            confirmationMessage += NSLocalizedString("Thank you for your payment.", comment: "")
        }
        if Environment.sharedInstance.opco != .bge {
            confirmationMessage += NSLocalizedString(" A confirmation email will be sent to your shortly.", comment: "")
        }
        confirmationLabel.text = confirmationMessage
        
        convenienceFeeLabel.textColor = .blackText
        convenienceFeeLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        paymentInfoView.backgroundColor = .softGray
        
        paymentDateTextLabel.textColor = .blackText
        paymentDateTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentDateTextLabel.text = NSLocalizedString("Payment Date", comment: "")
        paymentDateValueLabel.textColor = .blackText
        paymentDateValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountPaidTextLabel.textColor = .blackText
        amountPaidTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountPaidTextLabel.text = NSLocalizedString("Amount Paid", comment: "")
        amountPaidValueLabel.textColor = .blackText
        amountPaidValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        autoPayLabel.textColor = .deepGray
        autoPayLabel.font = SystemFont.regular.of(textStyle: .footnote)
        autoPayLabel.text = NSLocalizedString("Would you like to set up Automatic Payments?", comment: "")
        enrollAutoPayButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        
        privacyPolicyButton.setTitleColor(.actionBlue, for: .normal)
        privacyPolicyButton.setTitle(NSLocalizedString("Privacy Policy", comment: ""), for: .normal)
        
        bindViewHiding()
        bindViewContent()
    }
    
    func bindViewHiding() {
        viewModel.shouldShowBillMatrixView.map(!).drive(billMatrixView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowAutoPayEnrollButton.map(!).drive(autoPayView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowConvenienceFeeLabel.map(!).drive(convenienceFeeLabel.rx.isHidden).addDisposableTo(disposeBag)
    }
    
    func bindViewContent() {
        // Payment Date
        viewModel.paymentDateString.asDriver().drive(paymentDateValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Total Payment
        viewModel.totalPaymentDisplayString.asDriver().drive(amountPaidValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Conv. Fee Label
        viewModel.paymentAmountFeeFooterLabelText.asDriver().drive(convenienceFeeLabel.rx.text).addDisposableTo(disposeBag)
    }

    @IBAction func onXButtonPress() {
        if viewModel.paymentId.value != nil { // Modify Payment
            for vc in presentingNavController.viewControllers {
                guard let dest = vc as? BillingHistoryViewController else {
                    continue
                }
                dest.getBillingHistory()
                presentingNavController.popToViewController(dest, animated: false)
                break
            }
        } else {
            for vc in presentingNavController.viewControllers {
                guard let dest = vc as? BillViewController else {
                    continue
                }
                dest.viewModel.fetchAccountDetail(isRefresh: false)
                presentingNavController.popToViewController(dest, animated: false)
                break
            }
            presentingNavController.setNavigationBarHidden(true, animated: true) // Fixes bad dismiss animation
        }
        presentingNavController.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onEnrollInAutoPayPress() {
        for vc in presentingNavController.viewControllers {
            guard let dest = vc as? BillViewController else {
                continue
            }
            presentingNavController.popToViewController(dest, animated: false)
            //dest.viewModel.fetchAccountDetail(isRefresh: false) // Can't do this because currentAccountDetail will be nil in prepareForSegue
            dest.navigateToAutoPay()
            break
        }
        presentingNavController.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onPrivacyPolicyPress(_ sender: Any) {
        let tacModal = WebViewController(title: NSLocalizedString("Privacy Policy", comment: ""),
                                         url: URL(string:"https://webpayments.billmatrix.com/HTML/privacy_notice_en-us.html")!)
        present(tacModal, animated: true, completion: nil)
    }
    
}
