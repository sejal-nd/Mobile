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
    @IBOutlet weak var confirmationNumberDivider: UIView!
    @IBOutlet weak var confirmationNumberView: UIView!
    @IBOutlet weak var confirmationNumberTextLabel: UILabel!
    @IBOutlet weak var confirmationNumberValueLabel: UITextView!
    @IBOutlet weak var convenienceFeeLabel: UILabel!
    
    @IBOutlet weak var autoPayView: UIView!
    @IBOutlet weak var autoPayLabel: UILabel!
    @IBOutlet weak var enrollAutoPayButton: SecondaryButton!
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
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
        if Environment.shared.opco != .bge {
            confirmationMessage += NSLocalizedString(" A confirmation email will be sent to you shortly.", comment: "")
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
        confirmationNumberTextLabel.textColor = .blackText
        confirmationNumberTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        confirmationNumberTextLabel.text = NSLocalizedString("Confirmation Number", comment: "")
        confirmationNumberValueLabel.contentInset = .zero
        confirmationNumberValueLabel.textContainerInset = .zero
        confirmationNumberValueLabel.textColor = .blackText
        confirmationNumberValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        autoPayLabel.textColor = .deepGray
        autoPayLabel.font = SystemFont.regular.of(textStyle: .footnote)
        autoPayLabel.text = NSLocalizedString("Would you like to set up Automatic Payments?", comment: "")
        enrollAutoPayButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        
        footerView.backgroundColor = .softGray
        footerLabel.attributedText = viewModel.confirmationFooterText
        footerView.isHidden = !viewModel.showConfirmationFooterText
        
        bindViewHiding()
        bindViewContent()
    }
    
    func bindViewHiding() {
        viewModel.shouldShowAutoPayEnrollButton.map(!).drive(autoPayView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowConvenienceFeeLabel.map(!).drive(convenienceFeeLabel.rx.isHidden).disposed(by: disposeBag)
    }
    
    func bindViewContent() {
        // Payment Date
        viewModel.paymentDateString.asDriver().drive(paymentDateValueLabel.rx.text).disposed(by: disposeBag)
        
        // Total Payment
        viewModel.totalPaymentDisplayString.asDriver().drive(amountPaidValueLabel.rx.text).disposed(by: disposeBag)
        
        // Confirmation Number
        if let confirmationNumber = viewModel.confirmationNumber {
            confirmationNumberValueLabel.text = confirmationNumber
            confirmationNumberDivider.isHidden = false
            confirmationNumberView.isHidden = false
        } else {
            confirmationNumberDivider.isHidden = true
            confirmationNumberView.isHidden = true
        }
        
        // Conv. Fee Label
        viewModel.paymentAmountFeeFooterLabelText.asDriver().drive(convenienceFeeLabel.rx.text).disposed(by: disposeBag)
    }

    @IBAction func onXButtonPress() {
        if viewModel.paymentId.value != nil { // Edit Payment
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
                if let dest = vc as? BillViewController {
                    dest.viewModel.fetchAccountDetail(isRefresh: false)
                    presentingNavController.popToViewController(dest, animated: false)
                    presentingNavController.setNavigationBarHidden(true, animated: true) // Fixes bad dismiss animation
                    break
                } else if let dest = vc as? StormModeBillViewController {
                    dest.viewModel.fetchData.onNext(.switchAccount)
                    presentingNavController.popToViewController(dest, animated: false)
                    break
                }
            }
        }
        presentingNavController.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onEnrollInAutoPayPress() {
        GoogleAnalytics.log(event: .confirmationScreenAutopayEnroll)
        for vc in presentingNavController.viewControllers {
            if let dest = vc as? BillViewController {
                presentingNavController.popToViewController(dest, animated: false)
                //dest.viewModel.fetchAccountDetail(isRefresh: false) // Can't do this because currentAccountDetail will be nil in prepareForSegue
                presentingNavController.dismiss(animated: true, completion: { [weak self] in
                    NotificationCenter.default.post(name: .didSelectEnrollInAutoPay, object: self?.viewModel.accountDetail.value)
                })
                break
            } else if let dest = vc as? HomeViewController {
                GoogleAnalytics.log(event: .confirmationScreenAutopayEnroll)
                presentingNavController.popToViewController(dest, animated: false)
                let tabController = presentingNavController.tabBarController as! MainTabBarController
                tabController.selectedIndex = 1
                presentingNavController.setNavigationBarHidden(true, animated: true)
                presentingNavController.dismiss(animated: true, completion: { [weak self] in
                    NotificationCenter.default.post(name: .didSelectEnrollInAutoPay, object: self?.viewModel.accountDetail.value)
                })
                break
            }
        }
    }
    
}
