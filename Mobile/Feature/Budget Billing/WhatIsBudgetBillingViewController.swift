//
//  WhatIsBudgetBillingViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class WhatIsBudgetBillingViewController: DismissableFormSheetViewController {

    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var navTitleLabel: UILabel!
    @IBOutlet weak var navDescriptionLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet var bulletCollection: [UIView]!
    
    // Card 1
    @IBOutlet weak var card1View: UIView!
    @IBOutlet weak var card1TitleLabel: UILabel!
    @IBOutlet weak var card1Bullet1Label: UILabel!
    @IBOutlet weak var card1Bullet2Label: UILabel!
    @IBOutlet weak var card1Bullet3View: UIView!
    @IBOutlet weak var card1Bullet3Label: UILabel!
    
    // Card 2
    @IBOutlet weak var card2View: UIView!
    @IBOutlet weak var card2TitleLabel: UILabel!
    @IBOutlet weak var card2Bullet1Label: UILabel!
    @IBOutlet weak var card2Bullet2Label: UILabel!
    @IBOutlet weak var card2Bullet3Label: UILabel!
    @IBOutlet weak var card2Bullet4View: UIView!
    @IBOutlet weak var card2Bullet4Label: UILabel!
    @IBOutlet weak var card2Bullet5View: UIView!
    @IBOutlet weak var card2Bullet5Label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.backgroundColor = .primaryColor

        xButton.imageView?.tintColor = .actionBlue
        xButton.accessibilityLabel = NSLocalizedString("Close", comment: "")
        
        navBar.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 3), radius: 1)
        
        navTitleLabel.textColor = .blackText
        navTitleLabel.text = NSLocalizedString("What is Budget Billing?", comment: "")
        
        navDescriptionLabel.textColor = .deepGray
        navDescriptionLabel.font = OpenSans.regular.of(textStyle: .headline)
        
        card1View.layer.cornerRadius = 10
        card2View.layer.cornerRadius = 10
        
        card1TitleLabel.textColor = .primaryColorADA
        card1TitleLabel.text = NSLocalizedString("1 consistent bill over 12 months", comment: "")
        card2TitleLabel.textColor = .primaryColorADA
        card2TitleLabel.text = NSLocalizedString("Adjusted throughout the year", comment: "")
        
        for view in bulletCollection {
            view.backgroundColor = .primaryColor
            view.layer.cornerRadius = 3.5
        }
        
        card1Bullet1Label.textColor = .deepGray
        card1Bullet2Label.textColor = .deepGray
        card1Bullet3Label.textColor = .deepGray
        card2Bullet1Label.textColor = .deepGray
        card2Bullet2Label.textColor = .deepGray
        card2Bullet3Label.textColor = .deepGray
        card2Bullet4Label.textColor = .deepGray
        card2Bullet5Label.textColor = .deepGray
        
        card1Bullet1Label.font = OpenSans.regular.of(textStyle: .body)
        card1Bullet2Label.font = OpenSans.regular.of(textStyle: .body)
        card1Bullet3Label.font = OpenSans.regular.of(textStyle: .body)
        card2Bullet1Label.font = OpenSans.regular.of(textStyle: .body)
        card2Bullet2Label.font = OpenSans.regular.of(textStyle: .body)
        card2Bullet3Label.font = OpenSans.regular.of(textStyle: .body)
        card2Bullet4Label.font = OpenSans.regular.of(textStyle: .body)
        card2Bullet5Label.font = OpenSans.regular.of(textStyle: .body)
        
        // Those are ComEd only
        card2Bullet4View.isHidden = true
        card2Bullet5View.isHidden = true
        
        switch Environment.shared.opco {
        case OpCo.bge:
            navDescriptionLabel.text = NSLocalizedString("Budget Billing spreads out your utility payments evenly throughout the year, so you will know what to expect each month.", comment: "")
            card1Bullet1Label.text = NSLocalizedString("Under this payment plan, BGE calculates your budget bill amount by averaging your 12 most recent gas and electric bills plus any accumulated imbalance amount.", comment: "")
            card1Bullet2Label.text = NSLocalizedString("BGE will still continue to read your meter each month and your bill will always show details of the actual charges and consumption for the billing period, as well as your account balance.", comment: "")
            card1Bullet3View.isHidden = true
            
            card2Bullet1Label.text = NSLocalizedString("To prevent any large deficits or overpayments, BGE will review your account throughout the year. If your Budget Billing payment amount needs to be adjusted higher or lower than your current monthly payments to reflect your actual usage, BGE will notify you one month prior to the change with your new Budget Billing payment amount.", comment: "")
            card2Bullet2Label.text = NSLocalizedString("BGE will apply interest at one-half of one percent (0.5%) per month to any credit balance in your Budget Billing account. Any accumulated interest will be credited on your June bill.", comment: "")
            card2Bullet3Label.text = NSLocalizedString("If you have selected an alternate gas or electric supplier, BGE will still deliver your energy. However, your Budget Billing amount will only include your gas and/or electric delivery service charges from BGE. The charges from your supplier will be listed as a separate item on your bill.", comment: "")
        case OpCo.comEd:
            navDescriptionLabel.text = NSLocalizedString("Budget Billing spreads costs evenly month to month by charging a pre-arranged amount with each bill. It’s a predictable monthly payment that eliminates monthly or seasonal variation.", comment: "")
            card1Bullet1Label.text = NSLocalizedString("We calculate your monthly bill payment based on your usage during the last 12 months.", comment: "")
            card1Bullet2Label.text = NSLocalizedString("Your actual usage will continue to be shown on your monthly bill.", comment: "")
            card1Bullet3Label.text = NSLocalizedString("You may enroll at any time and your Budget Billing plan will begin with your next bill.", comment: "")
            
            card2Bullet1Label.text = NSLocalizedString("Your budget amount will be reviewed within the first two (2) months and could adjust based on actual usage.", comment: "")
            card2Bullet2Label.text = NSLocalizedString("After the initial review, your monthly Budget Bill payment will be reviewed and adjusted as needed every six (6) months to keep the payment in line with your actual usage.", comment: "")
            card2Bullet3Label.text = NSLocalizedString("Your account must be paid up to date. If you have two (2) consecutive late payments or three (3) late payments in a 12-month period you will be automatically removed from Budget Billing.", comment: "")
            card2Bullet4Label.text = NSLocalizedString("After 12 months, any credit/debit balances will be included in the calculation for the following year’s Budget Billing payment. If you prefer to have that credit/debit balance applied in full to your account, you may contact 1-800-EDISON1 after enrollment.", comment: "")
            card2Bullet5Label.text = NSLocalizedString("If you unenroll from Budget Billing, you will see your regular bill amount and any past differences between your Budget Billing amount and your actual charges on your next bill.", comment: "")
            card2Bullet4View.isHidden = false
            card2Bullet5View.isHidden = false
        case OpCo.peco:
            navDescriptionLabel.text = NSLocalizedString("Budget Billing spreads costs evenly month to month by charging a pre-arranged amount with each bill. It’s a predictable monthly payment that eliminates monthly or seasonal variation.", comment: "")
            card1Bullet1Label.text = NSLocalizedString("We calculate your monthly bill payment based on your usage during the last 12 months.", comment: "")
            card1Bullet2Label.text = NSLocalizedString("Your actual usage will continue to be shown on your monthly bill.", comment: "")
            card1Bullet3Label.text = NSLocalizedString("You may enroll at any time and your Budget Billing plan will begin with your next bill.", comment: "")
            
            card2Bullet1Label.text = NSLocalizedString("Your monthly Budget Bill payment will be adjusted every four (4) months to keep the payment in line with your actual usage.", comment: "")
            card2Bullet2Label.text = NSLocalizedString("After 12 months, your Budget Billing amount will be recalculated based on your previous 12-month's usage. This Budget Bill amount will be adjusted every four months to stay in line with your usage.", comment: "")
            card2Bullet3Label.text = NSLocalizedString("If you unenroll from Budget Billing, you will see your regular bill amount and any past differences between your Budget Billing amount and your actual charges on your next bill.", comment: "")
        }
        
        navDescriptionLabel.setLineHeight(lineHeight: 25)
        card1Bullet1Label.setLineHeight(lineHeight: 24)
        card1Bullet2Label.setLineHeight(lineHeight: 24)
        card1Bullet3Label.setLineHeight(lineHeight: 24)
        card2Bullet1Label.setLineHeight(lineHeight: 24)
        card2Bullet2Label.setLineHeight(lineHeight: 24)
        card2Bullet3Label.setLineHeight(lineHeight: 24)
        card2Bullet4Label.setLineHeight(lineHeight: 24)
        card2Bullet5Label.setLineHeight(lineHeight: 24)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    @IBAction func onXPress() {
        dismiss(animated: true, completion: nil)
    }
    
}
