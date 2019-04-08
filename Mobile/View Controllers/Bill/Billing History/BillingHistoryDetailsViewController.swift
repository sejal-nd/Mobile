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
    
    // Passed from BillingHistoryViewController/MoreBillingHistoryViewController
    var billingHistoryItem: BillingHistoryItem!

    var viewModel: BillingHistoryDetailsViewModel!
    
    @IBOutlet weak var paymentMethodView: UIView!
    @IBOutlet weak var paymentMethodLabel: UILabel!
    @IBOutlet weak var paymentMethodImageView: UIImageView!
    @IBOutlet weak var paymentMethodDetailsLabel: UILabel!
    @IBOutlet weak var paymentMethodSeparatorLine: UIView!
    
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
    
    @IBOutlet weak var paymentDateView: UIView!
    @IBOutlet weak var paymentDateLabel: UILabel!
    @IBOutlet weak var paymentDateDetailsLabel: UILabel!
    @IBOutlet weak var paymentDateSeparatorLine: UIView!
    
    @IBOutlet weak var paymentStatusView: UIView!
    @IBOutlet weak var paymentStatusLabel: UILabel!
    @IBOutlet weak var paymentStatusDetailsLabel: UILabel!
    @IBOutlet weak var paymentStatusSeparatorLine: UIView!
    
    @IBOutlet weak var confirmationNumberView: UIView!
    @IBOutlet weak var confirmationNumberLabel: UILabel!
    @IBOutlet weak var confirmationNumberDetailTextView: UITextView!
    @IBOutlet weak var confirmationNumberSeparatorView: UIView!
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Payment Details", comment: "")
        
        viewModel = BillingHistoryDetailsViewModel(billingHistoryItem: billingHistoryItem)
        
        styleViews()
        configureState()
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setColoredNavBar()
    }
    
    func styleViews() {
        paymentMethodLabel.textColor = .deepGray
        paymentMethodLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentMethodDetailsLabel.textColor = .blackText
        paymentMethodDetailsLabel.font = SystemFont.medium.of(textStyle: .headline)
        paymentMethodSeparatorLine.backgroundColor = .softGray
        
        paymentAmountLabel.textColor = .deepGray
        paymentAmountLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentAmountDetailsLabel.textColor = .successGreenText
        paymentAmountDetailsLabel.font = SystemFont.medium.of(textStyle: .headline)
        paymentAmountSeparatorLine.backgroundColor = .softGray
        
        convenienceFeeLabel.textColor = .deepGray
        convenienceFeeLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        convenienceFeeDetailsLabel.textColor = .successGreenText
        convenienceFeeDetailsLabel.font = SystemFont.medium.of(textStyle: .headline)
        convenienceFeeSeparatorLine.backgroundColor = .softGray
        
        totalAmountPaidLabel.textColor = .deepGray
        totalAmountPaidLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        totalAmountPaidDetailsLabel.textColor = .successGreenText
        totalAmountPaidDetailsLabel.font = SystemFont.medium.of(textStyle: .headline)
        totalAmountPaidSeparatorLine.backgroundColor = .softGray
        
        paymentDateLabel.textColor = .deepGray
        paymentDateLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentDateDetailsLabel.textColor = .blackText
        paymentDateDetailsLabel.font = SystemFont.medium.of(textStyle: .headline)
        paymentDateSeparatorLine.backgroundColor = .softGray
        
        paymentStatusLabel.textColor = .deepGray
        paymentStatusLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentStatusDetailsLabel.textColor = .blackText
        paymentStatusDetailsLabel.font = SystemFont.medium.of(textStyle: .headline)
        paymentStatusSeparatorLine.backgroundColor = .softGray
        
        confirmationNumberLabel.textColor = .deepGray
        confirmationNumberLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        confirmationNumberDetailTextView.textColor = .blackText
        confirmationNumberDetailTextView.font = SystemFont.medium.of(textStyle: .headline)
    }
    
    func configureState() {
        if let paymentMethodImage = viewModel.paymentMethodImage,
            let paymentMethodStr = viewModel.paymentMethodString {
            paymentMethodView.isHidden = false
            paymentMethodImageView.image = paymentMethodImage
            paymentMethodDetailsLabel.text = paymentMethodStr
        } else {
            paymentMethodView.isHidden = true
            paymentMethodSeparatorLine.isHidden = true
        }
        
        if let paymentAmount = viewModel.paymentAmount {
            paymentAmountView.isHidden = false
            paymentAmountDetailsLabel.text = paymentAmount
        } else {
            paymentAmountView.isHidden = true
            paymentAmountSeparatorLine.isHidden = true
        }
        
        if let convenienceFee = viewModel.convenienceFee {
            convenienceFeeView.isHidden = false
            convenienceFeeDetailsLabel.text = convenienceFee
        } else {
            convenienceFeeView.isHidden = true
            convenienceFeeSeparatorLine.isHidden = true
        }
        
        if let totalPaymentAmount = viewModel.totalPaymentAmount {
            totalAmountPaidView.isHidden = false
            totalAmountPaidDetailsLabel.text = totalPaymentAmount
        } else {
            totalAmountPaidView.isHidden = true
            totalAmountPaidSeparatorLine.isHidden = true
        }
        
        if let paymentDate = viewModel.paymentDate {
            paymentDateView.isHidden = false
            paymentDateDetailsLabel.text = paymentDate
        } else {
            paymentDateView.isHidden = true
            paymentDateSeparatorLine.isHidden = true
        }
        
        if let paymentStatus = viewModel.paymentStatus {
            paymentStatusView.isHidden = false
            paymentStatusDetailsLabel.text = paymentStatus
        } else {
            paymentStatusView.isHidden = true
            paymentStatusSeparatorLine.isHidden = true
        }
        
        if let confirmationNumber = viewModel.confirmationNumber {
            confirmationNumberView.isHidden = false
            confirmationNumberDetailTextView.text = confirmationNumber
        } else {
            confirmationNumberView.isHidden = true
            confirmationNumberSeparatorView.isHidden = true
        }
    }
    
}
