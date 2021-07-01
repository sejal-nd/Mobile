//
//  TapToPayConfirmationViewController.swift
//  EUMobile
//
//  Created by Adarsh Maurya on 19/10/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import RxSwift

class TapToPayConfirmationViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var xButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
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
    
    @IBOutlet weak var footerView: StickyFooterView!
    @IBOutlet weak var footerLabel: UILabel!
    
    var presentingNavController: UINavigationController! // Passed from ReviewPaymentViewController
    
    var viewModel: TapToPayViewModel! // Passed from ReviewPaymentViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        xButton.tintColor = .actionBlue
        xButton.accessibilityLabel = NSLocalizedString("Close", comment: "")

        titleLabel.textColor = .deepGray
        titleLabel.font = OpenSans.semibold.of(textStyle: .title3)
        
        confirmationLabel.textColor = .deepGray
        confirmationLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        paymentInfoView.layer.borderColor = UIColor.accentGray.cgColor
        paymentInfoView.layer.borderWidth = 1
        
        paymentDateTextLabel.textColor = .deepGray
        paymentDateTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentDateTextLabel.text = NSLocalizedString("Payment Date", comment: "")
        paymentDateValueLabel.textColor = .deepGray
        paymentDateValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountPaidTextLabel.textColor = .deepGray
        amountPaidTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountPaidTextLabel.text = NSLocalizedString("Amount Paid", comment: "")
        amountPaidValueLabel.textColor = .deepGray
        amountPaidValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        confirmationNumberTextLabel.textColor = .deepGray
        confirmationNumberTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        confirmationNumberTextLabel.text = NSLocalizedString("Confirmation Number", comment: "")
        confirmationNumberValueLabel.textContainerInset = .zero
        confirmationNumberValueLabel.textContainer.lineFragmentPadding = 0
        confirmationNumberValueLabel.textColor = .deepGray
        confirmationNumberValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        convenienceFeeLabel.textColor = .deepGray
        convenienceFeeLabel.font = OpenSans.regular.of(textStyle: .caption1)
        
        autoPayLabel.textColor = .deepGray
        autoPayLabel.font = SystemFont.regular.of(textStyle: .caption1)
        autoPayLabel.text = NSLocalizedString("Would you like to set up Automatic Payments?", comment: "")
        
        footerLabel.attributedText = viewModel.confirmationFooterText
        footerView.isHidden = !viewModel.showConfirmationFooterText
        
        bindViewHiding()
        bindViewContent()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configurePaymentSuccessMessage()
        
        // [iOS bug?] Need to set the text in here or the label doesn't wrap to 2 lines
        titleLabel.text = viewModel.paymentId.value != nil ?
            NSLocalizedString("Thank you for editing your payment.", comment: "") :
            NSLocalizedString("Thank you for your payment", comment: "")
    }
    
    func configurePaymentSuccessMessage() {
        if viewModel.emailAddress.value.isEmpty && viewModel.phoneNumber.value.isEmpty {
            confirmationLabel.text =  NSLocalizedString("You'll receive confirmation of this scheduled payment to the email associated with your My Account.", comment: "")
        } else {
            if let bankOrCard = viewModel.selectedWalletItem.value?.bankOrCard {
                
                var contactDetails = ""
                if viewModel.emailAddress.value.isEmpty {
                    contactDetails = " and \(viewModel.phoneNumber.value)."
                } else if viewModel.phoneNumber.value.isEmpty {
                    contactDetails = " and \(viewModel.emailAddress.value)."
                } else {
                    contactDetails = ", \(viewModel.emailAddress.value), and \(viewModel.phoneNumber.value)."
                }
                switch bankOrCard {
                case .bank:
                    let paymentSuccessMessage = NSLocalizedString("You'll receive confirmation of this scheduled payment request to the email associated with your My Account", comment: "")
                    confirmationLabel.text = paymentSuccessMessage + contactDetails
                case .card:
                    let paymentSuccessMessage = NSLocalizedString("You'll receive confirmation of this payment to the email associated with your My Account", comment: "")
                    confirmationLabel.text = paymentSuccessMessage + contactDetails
                }
            }
        }
    }
    
    func bindViewHiding() {
        viewModel.shouldShowAutoPayEnrollButton.map(!).drive(autoPayView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowConvenienceFeeLabel.map(!).drive(convenienceFeeLabel.rx.isHidden).disposed(by: disposeBag)
    }
    
    func bindViewContent() {
        // Payment Date
        viewModel.paymentDateStringOnConfirmationScreen.asDriver().drive(paymentDateValueLabel.rx.text).disposed(by: disposeBag)
        
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
            for vc in presentingNavController.viewControllers {
                if let dest = vc as? BillViewController {
                    dest.viewModel.fetchAccountDetail(isRefresh: false)
                    presentingNavController.popToViewController(dest, animated: false)
                    presentingNavController.setNavigationBarHidden(true, animated: true) // Fixes bad dismiss animation
                    break
                } else if let dest = vc as? StormModeBillViewController {
                    dest.viewModel.fetchData.onNext(())
                    presentingNavController.popToViewController(dest, animated: false)
                    break
                }
                else if let _ = vc as? TapToPayReviewPaymentViewController {
                    NotificationCenter.default.post(name: .didRecievePaymentConfirmation, object: nil)
                    presentingNavController.dismiss(animated: true, completion: nil)
                }
            }

        presentingNavController.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onEnrollInAutoPayPress() {
        GoogleAnalytics.log(event: .confirmationScreenAutopayEnroll)
        NotificationCenter.default.post(name: .didSelectEnrollInAutoPay, object: self.viewModel.accountDetail.value)
        NotificationCenter.default.post(name: .didRecievePaymentConfirmation, object: nil)
        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        FirebaseUtility.logEvent(.payment(parameters: [.autopay]))
        for vc in presentingNavController.viewControllers {
            if let dest = vc as? TapToPayReviewPaymentViewController {
                presentingNavController.popToViewController(dest, animated: false)
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
