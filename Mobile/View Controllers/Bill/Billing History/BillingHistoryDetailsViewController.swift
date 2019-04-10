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
    
    @IBOutlet var dividerLines: [UIView]!
    @IBOutlet var dividerLineConstraints: [NSLayoutConstraint]!
    
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
        
        paymentAmountLabel.textColor = .deepGray
        paymentAmountLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentAmountDetailsLabel.textColor = .successGreenText
        paymentAmountDetailsLabel.font = SystemFont.medium.of(textStyle: .headline)
        
        convenienceFeeLabel.textColor = .deepGray
        convenienceFeeLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        convenienceFeeDetailsLabel.textColor = .successGreenText
        convenienceFeeDetailsLabel.font = SystemFont.medium.of(textStyle: .headline)
        
        totalAmountPaidLabel.textColor = .deepGray
        totalAmountPaidLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        totalAmountPaidDetailsLabel.textColor = .successGreenText
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
        
        for dividerLine in dividerLines {
            dividerLine.backgroundColor = .accentGray
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
    }
    
}
