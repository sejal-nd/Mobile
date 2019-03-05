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

    var billingHistoryItem: BillingHistoryItem!
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var paymentTypeView: UIView!
    @IBOutlet weak var paymentTypeLabel: UILabel!
    @IBOutlet weak var paymentTypeDetailLabel: UILabel!
    
    @IBOutlet weak var paymentTypeSeparatorLine: UIView!
    
    @IBOutlet weak var paymentAccountView: UIView!
    @IBOutlet weak var paymentAccountLabel: UILabel!
    @IBOutlet weak var paymentAccountDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentAccountSeparatorLine: UIView!
    
    @IBOutlet weak var paymentDateView: UIView!
    @IBOutlet weak var paymentDateLabel: UILabel!
    @IBOutlet weak var paymentDateDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentDateSeparatorLine: UIView!
    
    @IBOutlet weak var paymentAmountView: UIView!
    @IBOutlet weak var paymentAmountLabel: UILabel!
    @IBOutlet weak var paymentAmountDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentAmountSeparatorLine: UIView!
    
    @IBOutlet weak var convenienceFeeView: UIView!
    @IBOutlet weak var convenienceFeeLabel: UILabel!
    @IBOutlet weak var convenienceFeeDetailsLabel: UILabel!
    
    @IBOutlet weak var convenienceFeeSeparatorLine: UIView!
    
    @IBOutlet weak var totalAmountPaidView: UIView!
    @IBOutlet weak var totalAmountPaidLabel: UILabel!
    @IBOutlet weak var totalAmountPaidDetailsLabel: UILabel!
    
    @IBOutlet weak var totalAmountPaidSeparatorLine: UIView!
    
    @IBOutlet weak var paymentStatusView: UIView!
    @IBOutlet weak var paymentStatusLabel: UILabel!
    @IBOutlet weak var paymentStatusDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentStatusSeparatorLine: UIView!
    
    @IBOutlet weak var confirmationNumberView: UIView!
    @IBOutlet weak var confirmationNumberLabel: UILabel!
    @IBOutlet weak var confirmationNumberDetailsLabel: UILabel!
    
    var viewModel: BillingHistoryDetailsViewModel!
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Payment Details", comment: "")
        
        viewModel = BillingHistoryDetailsViewModel(paymentService: ServiceFactory.createPaymentService(), billingHistoryItem: billingHistoryItem)
        
        formatViews()
        styleViews()
        bindLoadingStates()
        
        // We may be able to restore this for ComEd/PECO with ePay R2
        if Environment.shared.opco == .bge {
            viewModel.fetchPaymentDetails(billingHistoryItem: billingHistoryItem, onCompletion: {
                UIAccessibility.post(notification: .screenChanged, argument: self.scrollView)
            })
        }
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setColoredNavBar()
    }
    
    func formatViews() {
        if Environment.shared.opco != .bge {
            paymentTypeView.isHidden = true
            paymentTypeLabel.isAccessibilityElement = false
            paymentTypeSeparatorLine.isHidden = true
            
            paymentAccountView.isHidden = true
            paymentAccountLabel.isAccessibilityElement = false
            paymentAccountSeparatorLine.isHidden = true
            
            convenienceFeeView.isHidden = true
            convenienceFeeLabel.isAccessibilityElement = false
            convenienceFeeSeparatorLine.isHidden = true
            
            totalAmountPaidView.isHidden = true
            totalAmountPaidLabel.isAccessibilityElement = false
            totalAmountPaidSeparatorLine.isHidden = true
            
            confirmationNumberView.isHidden = true
            confirmationNumberLabel.isAccessibilityElement = false
        } else {
            if viewModel.isSpeedpay {
                paymentTypeView.isHidden = true
                paymentTypeLabel.isAccessibilityElement = false
                paymentTypeSeparatorLine.isHidden = true
            } else {
                paymentAccountView.isHidden = true
                paymentAccountLabel.isAccessibilityElement = false
                paymentAccountSeparatorLine.isHidden = true
                
                convenienceFeeView.isHidden = true
                convenienceFeeLabel.isAccessibilityElement = false
                convenienceFeeSeparatorLine.isHidden = true
                
                totalAmountPaidView.isHidden = true
                totalAmountPaidLabel.isAccessibilityElement = false
                totalAmountPaidSeparatorLine.isHidden = true
            }
        }
    }
    
    func styleViews() {
        
        paymentTypeLabel.textColor = .deepGray
        paymentTypeLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentTypeDetailLabel.textColor = .black
        paymentTypeDetailLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        paymentTypeSeparatorLine.backgroundColor = .softGray
        
        paymentAccountLabel.textColor = .deepGray
        paymentAccountLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentAccountDetailsLabel.textColor = .black
        paymentAccountDetailsLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        paymentAccountSeparatorLine.backgroundColor = .softGray
        
        paymentDateLabel.textColor = .deepGray
        paymentDateLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentDateDetailsLabel.textColor = .black
        paymentDateDetailsLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        paymentDateSeparatorLine.backgroundColor = .softGray
        
        paymentAmountLabel.textColor = .deepGray
        paymentAmountLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentAmountDetailsLabel.textColor = .successGreenText
        paymentAmountDetailsLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        paymentAmountSeparatorLine.backgroundColor = .softGray
        
        convenienceFeeLabel.textColor = .deepGray
        convenienceFeeLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        convenienceFeeDetailsLabel.textColor = .successGreenText
        convenienceFeeDetailsLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        convenienceFeeSeparatorLine.backgroundColor = .softGray
        
        totalAmountPaidLabel.textColor = .deepGray
        totalAmountPaidLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        totalAmountPaidDetailsLabel.textColor = .successGreenText
        totalAmountPaidDetailsLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        totalAmountPaidSeparatorLine.backgroundColor = .softGray
        
        paymentStatusLabel.textColor = .deepGray
        paymentStatusLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentStatusDetailsLabel.textColor = .black
        paymentStatusDetailsLabel.font = SystemFont.bold.of(textStyle: .headline)

        paymentStatusSeparatorLine.backgroundColor = .softGray
        
        confirmationNumberLabel.textColor = .deepGray
        confirmationNumberLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        confirmationNumberDetailsLabel.textColor = .black
        confirmationNumberDetailsLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
    }
    
    func bindLoadingStates() {
        viewModel.paymentAccount.drive(paymentAccountDetailsLabel.rx.text).disposed(by: bag)
        
        paymentTypeLabel.text = viewModel.paymentTypeLabel
        paymentTypeDetailLabel.text = viewModel.paymentType
        paymentDateDetailsLabel.text = viewModel.paymentDate
        paymentAmountLabel.text = viewModel.paymentAmountLabel
        paymentAmountDetailsLabel.text = viewModel.amountPaid
        
        viewModel.shouldShowContent.not().drive(scrollView.rx.isHidden).disposed(by: bag)
        viewModel.fetching.asDriver().map(!).drive(loadingIndicator.rx.isHidden).disposed(by: bag)
        viewModel.isError.asDriver().not().drive(errorLabel.rx.isHidden).disposed(by: bag)
        
        viewModel.convenienceFee.drive(convenienceFeeDetailsLabel.rx.text).disposed(by: bag)
        viewModel.totalAmountPaid.drive(totalAmountPaidDetailsLabel.rx.text).disposed(by: bag)
        
        paymentStatusDetailsLabel.text = viewModel.paymentStatus
        confirmationNumberDetailsLabel.text = viewModel.confirmationNumber

    }
    
}
