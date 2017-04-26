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
    
    @IBOutlet var bulletCollection: [UIView]!
    
    // Card 1
    @IBOutlet weak var card1TitleLabel: UILabel!
    @IBOutlet weak var card1Bullet1Label: UILabel!
    @IBOutlet weak var card1Bullet2Label: UILabel!
    @IBOutlet weak var card1Bullet3View: UIView!
    @IBOutlet weak var card1Bullet3Label: UILabel!
    
    // Card 2
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
        
        view.backgroundColor = .primaryColor

        xButton.imageView?.tintColor = .primaryColor
        
        navBar.layer.shadowRadius = 3
        navBar.layer.shadowColor = UIColor.black.cgColor
        navBar.layer.shadowOpacity = 0.2
        navBar.layer.shadowOffset = CGSize(width: 0, height: 1)
        navBar.layer.masksToBounds = false
        
        navTitleLabel.textColor = .darkJungleGreen
        navTitleLabel.text = NSLocalizedString("What is Budget Billing?", comment: "")
        
        navDescriptionLabel.textColor = .outerSpace
        
        card1TitleLabel.textColor = .primaryColorDark
        card1TitleLabel.text = NSLocalizedString("1 consistent bill over 12 months", comment: "")
        card2TitleLabel.textColor = .primaryColorDark
        card2TitleLabel.text = NSLocalizedString("Adjusted throughout the year", comment: "")
        
        for view in bulletCollection {
            view.backgroundColor = .primaryColor
            view.layer.cornerRadius = 3.5
        }
        
        card1Bullet1Label.textColor = .outerSpace
        card1Bullet2Label.textColor = .outerSpace
        card1Bullet3Label.textColor = .outerSpace
        card2Bullet1Label.textColor = .outerSpace
        card2Bullet2Label.textColor = .outerSpace
        card2Bullet3Label.textColor = .outerSpace
        card2Bullet4Label.textColor = .outerSpace
        card2Bullet5Label.textColor = .outerSpace
        
        // Those are ComEd only
        card2Bullet4View.isHidden = true
        card2Bullet5View.isHidden = true
        
        switch Environment.sharedInstance.opco {
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
            card2Bullet2Label.text = NSLocalizedString("After 12 months of Budget Billing, the difference between your budget bill amount and actual use for the previous 12 months will be applied to your bill. If you have used more than what you have been charged for, the difference will be added to your bill. If you use less your bill will be credited the difference.", comment: "")
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

    @IBAction func onXPress() {
        dismiss(animated: true, completion: nil)
    }
}
