//
//  WhatIsBudgetBillingViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class WhatIsBudgetBillingViewController: DismissableFormSheetViewController {

    @IBOutlet weak var card1TitleLabel: UILabel!
    @IBOutlet weak var card1Bullet1Label: UILabel!
    @IBOutlet weak var card1Bullet2Label: UILabel!
    @IBOutlet weak var card1Bullet3Label: UILabel!
    @IBOutlet weak var card1Bullet4Label: UILabel!
    
    @IBOutlet weak var card2TitleLabel: UILabel!
    @IBOutlet weak var card2Bullet1Label: UILabel!
    @IBOutlet weak var card2Bullet2Label: UILabel!
    @IBOutlet weak var card2Bullet3Label: UILabel!
    @IBOutlet weak var card2Bullet4Label: UILabel!
    @IBOutlet weak var card2Bullet5Label: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCloseButton()
        descriptionLabel.isHidden = !Environment.shared.opco.isPHI
        card1TitleLabel.textColor = .deepGray
        card1TitleLabel.font = OpenSans.semibold.of(textStyle: .title3)
        card1TitleLabel.text = NSLocalizedString("1 consistent bill over 12 months", comment: "")
        card2TitleLabel.textColor = .deepGray
        card2TitleLabel.font = OpenSans.semibold.of(textStyle: .title3)
        card2TitleLabel.text = NSLocalizedString("Adjusted throughout the year", comment: "")
        
        card1Bullet1Label.textColor = .deepGray
        card1Bullet2Label.textColor = .deepGray
        card1Bullet3Label.textColor = .deepGray
        card1Bullet4Label.textColor = .deepGray

        card2Bullet1Label.textColor = .deepGray
        card2Bullet2Label.textColor = .deepGray
        card2Bullet3Label.textColor = .deepGray
        card2Bullet4Label.textColor = .deepGray
        card2Bullet5Label.textColor = .deepGray
        
        descriptionLabel.textColor = .deepGray
        
        card1Bullet1Label.font = OpenSans.regular.of(textStyle: .body)
        card1Bullet2Label.font = OpenSans.regular.of(textStyle: .body)
        card1Bullet3Label.font = OpenSans.regular.of(textStyle: .body)
        card1Bullet4Label.font = OpenSans.regular.of(textStyle: .body)

        card2Bullet1Label.font = OpenSans.regular.of(textStyle: .body)
        card2Bullet2Label.font = OpenSans.regular.of(textStyle: .body)
        card2Bullet3Label.font = OpenSans.regular.of(textStyle: .body)
        card2Bullet4Label.font = OpenSans.regular.of(textStyle: .body)
        card2Bullet5Label.font = OpenSans.regular.of(textStyle: .body)
        
        descriptionLabel.font = OpenSans.regular.of(textStyle: .body)

        switch Environment.shared.opco {
        case .bge:
            card1Bullet1Label.text = NSLocalizedString("Under this payment plan, BGE calculates your budget bill amount by averaging your 12 most recent gas and electric bills plus any accumulated imbalance amount.", comment: "")
            card1Bullet2Label.text = NSLocalizedString("BGE will still continue to read your meter each month and your bill will always show details of the actual charges and consumption for the billing period, as well as your account balance.", comment: "")
            card1Bullet3Label.isHidden = true
            
            card2Bullet1Label.text = NSLocalizedString("To prevent any large deficits or overpayments, BGE will review your account throughout the year. If your Budget Billing payment amount needs to be adjusted higher or lower than your current monthly payments to reflect your actual usage, BGE will notify you one month prior to the change with your new Budget Billing payment amount.", comment: "")
            card2Bullet2Label.text = NSLocalizedString("BGE will apply interest at one-half of one percent (0.5%) per month to any credit balance in your Budget Billing account. Any accumulated interest will be credited on your June bill.", comment: "")
            card2Bullet3Label.text = NSLocalizedString("If you have selected an alternate gas or electric supplier, BGE will still deliver your energy. However, your Budget Billing amount will only include your gas and/or electric delivery service charges from BGE. The charges from your supplier will be listed as a separate item on your bill.", comment: "")
            card1Bullet4Label.isHidden = true
            card2Bullet4Label.isHidden = true
            card2Bullet5Label.isHidden = true
        case .comEd:
            card1Bullet1Label.text = NSLocalizedString("We calculate your monthly bill payment based on your usage during the last 12 months.", comment: "")
            card1Bullet2Label.text = NSLocalizedString("Your actual usage will continue to be shown on your monthly bill.", comment: "")
            card1Bullet3Label.text = NSLocalizedString("You may enroll at any time and your Budget Billing plan will begin with your next bill.", comment: "")
            
            card2Bullet1Label.text = NSLocalizedString("Your budget amount will be reviewed within the first two (2) months and could adjust based on actual usage.", comment: "")
            card2Bullet2Label.text = NSLocalizedString("After the initial review, your monthly Budget Bill payment will be reviewed and adjusted as needed every six (6) months to keep the payment in line with your actual usage.", comment: "")
            card2Bullet3Label.text = NSLocalizedString("Your account must be paid up to date. If you have two (2) consecutive late payments or three (3) late payments in a 12-month period you will be automatically removed from Budget Billing.", comment: "")
            card2Bullet4Label.text = NSLocalizedString("After 12 months, any credit/debit balances will be included in the calculation for the following year’s Budget Billing payment. If you prefer to have that credit/debit balance applied in full to your account, you may contact 1-800-EDISON1 after enrollment.", comment: "")
            card2Bullet5Label.text = NSLocalizedString("If you unenroll from Budget Billing, you will see your regular bill amount and any past differences between your Budget Billing amount and your actual charges on your next bill.", comment: "")
            card1Bullet4Label.isHidden = true
        case .peco:
            card1Bullet1Label.text = NSLocalizedString("We calculate your monthly bill payment based on your usage during the last 12 months.", comment: "")
            card1Bullet2Label.text = NSLocalizedString("Your actual usage will continue to be shown on your monthly bill.", comment: "")
            card1Bullet3Label.text = NSLocalizedString("You may enroll at any time and your Budget Billing plan will begin with your next bill.", comment: "")
            
            card2Bullet1Label.text = NSLocalizedString("Your monthly Budget Bill payment will be adjusted every four (4) months to keep the payment in line with your actual usage.", comment: "")
            card2Bullet2Label.text = NSLocalizedString("After 12 months, your Budget Billing amount will be recalculated based on your previous 12-month's usage. This Budget Bill amount will be adjusted every four months to stay in line with your usage.", comment: "")
            card2Bullet3Label.text = NSLocalizedString("If you unenroll from Budget Billing, you will see your regular bill amount and any past differences between your Budget Billing amount and your actual charges on your next bill.", comment: "")
            card1Bullet4Label.isHidden = true
            card2Bullet4Label.isHidden = true
            card2Bullet5Label.isHidden = true
        case .ace, .delmarva, .pepco:
            descriptionLabel.text = NSLocalizedString("Budget Billing averages out your annual energy cost to create a balanced and predictable monthly bill.", comment: "")
            card1Bullet1Label.text = NSLocalizedString("Your monthly Budget Billing payment amount is calculated based on your usage during the last 12 months.", comment: "")
            card1Bullet2Label.text = NSLocalizedString("Your actual usage will continue to be shown on your monthly bill.", comment: "")
            card1Bullet3Label.text = NSLocalizedString("You may enroll at any time and your Budget Billing plan will begin with your next bill.", comment: "")
            card1Bullet4Label.text = NSLocalizedString("Your account must be paid on time. If you miss any 2 payments within a rolling 12-month period you will be removed from Budget Billing.", comment: "")

            card2Bullet1Label.text = NSLocalizedString("Your Budget Billing payment amount will be reviewed periodically and may be adjusted based on actual usage.", comment: "")
            card2Bullet2Label.text = NSLocalizedString("After the initial review, your monthly Budget Bill payment will be reviewed and adjusted every year between the 7th and 10th months. Recalculation will only happen once during this period.", comment: "")
            card2Bullet3Label.text = NSLocalizedString("After 12 months, any credit balance will be included in the calculation for the following year’s Budget Billing payment.", comment: "")
            card2Bullet4Label.text = NSLocalizedString("Any outstanding balance is due at the end of the plan year. Outstanding balances are not automatically rolled into the next years’ Budget Billing plan.", comment: "")
            card2Bullet5Label.text = NSLocalizedString("If you unenroll from Budget Billing, you will see your regular bill amount and any past differences between your Budget Billing payment amount and your actual charges on your next bill.", comment: "")
        }
        
        card1Bullet1Label.setLineHeight(lineHeight: 24)
        card1Bullet2Label.setLineHeight(lineHeight: 24)
        card1Bullet3Label.setLineHeight(lineHeight: 24)
        card1Bullet4Label.setLineHeight(lineHeight: 24)
        card2Bullet1Label.setLineHeight(lineHeight: 24)
        card2Bullet2Label.setLineHeight(lineHeight: 24)
        card2Bullet3Label.setLineHeight(lineHeight: 24)
        card2Bullet4Label.setLineHeight(lineHeight: 24)
        card2Bullet5Label.setLineHeight(lineHeight: 24)
    }
    
}
