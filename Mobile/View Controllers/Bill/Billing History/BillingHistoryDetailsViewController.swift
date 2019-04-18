//
//  BillingHistoryDetailsViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt

class BillingHistoryDetailsViewController: UIViewController {
    
    // Passed from BillingHistoryViewController
    var accountDetail: AccountDetail!
    var billingHistoryItem: BillingHistoryItem!

    var viewModel: BillingHistoryDetailsViewModel!
    
    @IBOutlet weak var paymentMethodView: UIView!
    @IBOutlet weak var paymentMethodLabel: UILabel!
    @IBOutlet weak var paymentMethodImageView: UIImageView!
    @IBOutlet weak var paymentMethodDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentTypeView: UIView!
    @IBOutlet weak var paymentTypeLabel: UILabel!
    @IBOutlet weak var paymentTypeDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentAmountView: UIView!
    @IBOutlet weak var paymentAmountLabel: UILabel!
    @IBOutlet weak var paymentAmountDetailsLabel: UILabel!
    
    @IBOutlet weak var convenienceFeeView: UIView!
    @IBOutlet weak var convenienceFeeLabel: UILabel!
    @IBOutlet weak var convenienceFeeDetailsLabel: UILabel!
    
    @IBOutlet weak var totalAmountPaidView: UIView!
    @IBOutlet weak var totalAmountPaidLabel: UILabel!
    @IBOutlet weak var totalAmountPaidDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentDateView: UIView!
    @IBOutlet weak var paymentDateLabel: UILabel!
    @IBOutlet weak var paymentDateDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentStatusView: UIView!
    @IBOutlet weak var paymentStatusLabel: UILabel!
    @IBOutlet weak var paymentStatusDetailsLabel: UILabel!
    
    @IBOutlet weak var confirmationNumberView: UIView!
    @IBOutlet weak var confirmationNumberLabel: UILabel!
    @IBOutlet weak var confirmationNumberDetailTextView: ZeroInsetDataDetectorTextView!
    
    @IBOutlet weak var cancelPaymentView: UIView!
    @IBOutlet weak var cancelPaymentButton: ButtonControl!
    @IBOutlet weak var cancelPaymentLabel: UILabel!
    
    @IBOutlet var dividerLines: [UIView]!
    @IBOutlet var dividerLineConstraints: [NSLayoutConstraint]!
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Payment Details", comment: "")
        
        viewModel = BillingHistoryDetailsViewModel(paymentService: ServiceFactory.createPaymentService(),
                                                   accountDetail: accountDetail,
                                                   billingHistoryItem: billingHistoryItem)
        
        styleViews()
        configureState()
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setColoredNavBar()
    }
    
    override func updateViewConstraints() {
        for constraint in dividerLineConstraints {
            constraint.constant = 1.0 / UIScreen.main.scale
        }
        super.updateViewConstraints()
    }
    
    func styleViews() {
        paymentMethodLabel.textColor = .deepGray
        paymentMethodLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentMethodDetailsLabel.textColor = .blackText
        paymentMethodDetailsLabel.font = SystemFont.medium.of(textStyle: .headline)
        
        paymentTypeLabel.textColor = .deepGray
        paymentTypeLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentTypeDetailsLabel.textColor = .blackText
        paymentTypeDetailsLabel.font = SystemFont.medium.of(textStyle: .headline)
        
        paymentAmountLabel.textColor = .deepGray
        paymentAmountLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentAmountDetailsLabel.textColor = .blackText
        paymentAmountDetailsLabel.font = SystemFont.medium.of(textStyle: .headline)
        
        convenienceFeeLabel.textColor = .deepGray
        convenienceFeeLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        convenienceFeeDetailsLabel.textColor = .blackText
        convenienceFeeDetailsLabel.font = SystemFont.medium.of(textStyle: .headline)
        
        totalAmountPaidLabel.textColor = .deepGray
        totalAmountPaidLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        totalAmountPaidDetailsLabel.textColor = .blackText
        totalAmountPaidDetailsLabel.font = SystemFont.medium.of(textStyle: .headline)
        
        paymentDateLabel.textColor = .deepGray
        paymentDateLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentDateDetailsLabel.textColor = .blackText
        paymentDateDetailsLabel.font = SystemFont.medium.of(textStyle: .headline)
        
        paymentStatusLabel.textColor = .deepGray
        paymentStatusLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentStatusDetailsLabel.textColor = .blackText
        paymentStatusDetailsLabel.font = SystemFont.medium.of(textStyle: .headline)
        
        confirmationNumberLabel.textColor = .deepGray
        confirmationNumberLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        confirmationNumberDetailTextView.textColor = .blackText
        confirmationNumberDetailTextView.font = SystemFont.medium.of(textStyle: .headline)
        confirmationNumberDetailTextView.dataDetectorTypes.remove(.all)
        
        let cancelPaymentText = NSLocalizedString("Cancel Payment", comment: "")
        cancelPaymentButton.accessibilityLabel = cancelPaymentText
        cancelPaymentLabel.text = cancelPaymentText
        cancelPaymentLabel.font = SystemFont.regular.of(textStyle: .headline)
        cancelPaymentLabel.textColor = .actionBlue
        
        for line in dividerLines {
            line.backgroundColor = .accentGray
        }
    }
    
    func configureState() {
        if let paymentMethodImage = viewModel.paymentMethodImage,
            let paymentMethodStr = viewModel.paymentMethodString {
            paymentMethodImageView.image = paymentMethodImage
            paymentMethodDetailsLabel.text = paymentMethodStr
        } else {
            paymentMethodView.isHidden = true
        }
        
        if let paymentType = viewModel.paymentType {
            paymentTypeDetailsLabel.text = paymentType
        } else {
            paymentTypeView.isHidden = true
        }
        
        if let paymentAmount = viewModel.paymentAmount {
            paymentAmountDetailsLabel.text = paymentAmount
        } else {
            paymentAmountView.isHidden = true
        }
        
        if let convenienceFee = viewModel.convenienceFee {
            convenienceFeeDetailsLabel.text = convenienceFee
        } else {
            convenienceFeeView.isHidden = true
        }
        
        if let totalPaymentAmount = viewModel.totalPaymentAmount {
            totalAmountPaidDetailsLabel.text = totalPaymentAmount
        } else {
            totalAmountPaidView.isHidden = true
        }
        
        if let paymentDate = viewModel.paymentDate {
            paymentDateDetailsLabel.text = paymentDate
        } else {
            paymentDateView.isHidden = true
        }
        
        if let paymentStatus = viewModel.paymentStatus {
            paymentStatusDetailsLabel.text = paymentStatus
        } else {
            paymentStatusView.isHidden = true
        }
        
        if let confirmationNumber = viewModel.confirmationNumber {
            confirmationNumberDetailTextView.text = confirmationNumber
        } else {
            confirmationNumberView.isHidden = true
        }
        
        if !viewModel.shouldShowCancelPayment {
            cancelPaymentView.isHidden = true
        }
    }
    
    @IBAction func onCancelPaymentPress() {
        let alertTitle = NSLocalizedString("Are you sure you want to cancel this automatic payment?", comment: "")
        let alertMessage = NSLocalizedString("Canceling this payment will not impact your AutoPay enrollment. Future bills will still be paid automatically.", comment: "")
        let alertConfirm = NSLocalizedString("Yes", comment: "")
        let alertDeny = NSLocalizedString("No", comment: "")
        
        let confirmAlert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: alertDeny, style: .cancel, handler: nil))
        confirmAlert.addAction(UIAlertAction(title: alertConfirm, style: .destructive, handler: { [weak self] _ in
            LoadingView.show()
            self?.viewModel.cancelPayment(onSuccess: { [weak self] in
                LoadingView.hide()
                guard let self = self, let navigationController = self.navigationController else { return }
                for vc in navigationController.viewControllers {
                    // Always pop back to the root billing history screen here (hence the check for viewingMoreActivity)
                    guard let dest = vc as? BillingHistoryViewController, !dest.viewModel.viewingMoreActivity else {
                        continue
                    }
                    dest.onPaymentCancel()
                    navigationController.popToViewController(dest, animated: true)
                    return
                }
                navigationController.popViewController(animated: true)
            }, onError: { [weak self] errMessage in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
            })
        }))
        present(confirmAlert, animated: true, completion: nil)
    }
    
}
