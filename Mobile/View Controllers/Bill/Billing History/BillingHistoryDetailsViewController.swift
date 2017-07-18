//
//  BillingHistoryDetailsViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class BillingHistoryDetailsViewController: UIViewController {

    var billingHistoryItem: BillingHistoryItem!
    
    @IBOutlet weak var paymentAccountStackView: UIStackView!
    @IBOutlet weak var paymentAccountLabel: UILabel!
    @IBOutlet weak var paymentAccountDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentAccountSeparatorLine: UIView!
    
    @IBOutlet weak var paymentDateStackView: UIStackView!
    @IBOutlet weak var paymentDateLabel: UILabel!
    @IBOutlet weak var paymentDateDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentDateSeparatorLine: UIView!
    
    @IBOutlet weak var paymentAmountStackView: UIStackView!
    @IBOutlet weak var paymentAmountLabel: UILabel!
    @IBOutlet weak var paymentAmountDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentAmountSeparatorLine: UIView!
    
    @IBOutlet weak var convenienceFeeStackView: UIStackView!
    @IBOutlet weak var convenienceFeeLabel: UILabel!
    @IBOutlet weak var convenienceFeeDetailsLabel: UILabel!
    
    @IBOutlet weak var convenienceFeeSeparatorLine: UIView!
    
    @IBOutlet weak var totalAmountPaidStackView: UIStackView!
    @IBOutlet weak var totalAmountPaidLabel: UILabel!
    @IBOutlet weak var totalAmountPaidDetailsLabel: UILabel!
    
    @IBOutlet weak var totalAmountPaidSeparatorLine: UIView!
    
    @IBOutlet weak var paymentStatusStackView: UIStackView!
    @IBOutlet weak var paymentStatusLabel: UILabel!
    @IBOutlet weak var paymentStatusDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentStatusSeparatorLine: UIView!
    
    @IBOutlet weak var confirmationNumberStackView: UIStackView!
    @IBOutlet weak var confirmationNumberLabel: UILabel!
    @IBOutlet weak var confirmationNumberDetailsLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Payment Details", comment: "")

        formatSections()
        
        populateWithData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar(hidesBottomBorder: true)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func formatSections() {
        let opco = Environment.sharedInstance.opco
        
        if opco != .bge {
            // show payment date, amount paid, payment status
            // hide the rest
            paymentAccountStackView.isHidden = true
            paymentAccountSeparatorLine.isHidden = true
            
            convenienceFeeStackView.isHidden = true
            convenienceFeeSeparatorLine.isHidden = true
            
            totalAmountPaidStackView.isHidden = true
            totalAmountPaidSeparatorLine.isHidden = true
            
            confirmationNumberStackView.isHidden = true
        } else {
            
        }
        
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
    }
    
    func populateWithData() {
        paymentAccountDetailsLabel.text = AccountsStore.sharedInstance.currentAccount.accountNumber

        if self.billingHistoryItem.date != nil {
            paymentDateDetailsLabel.text = self.billingHistoryItem.date.mmDdYyyyString
        } else {
            paymentDateStackView.isHidden = true
            paymentAmountSeparatorLine.isHidden = true
        }
        
        if let amountPaid = self.billingHistoryItem.amountPaid {
            paymentAmountDetailsLabel.text = "$\(String(describing: amountPaid))"
        } else {
            paymentAmountStackView.isHidden = true
            paymentAmountSeparatorLine.isHidden = true
//            paymentAmountDetailsLabel.text = "$0.00"
        }
        
        if let chargeAmount = self.billingHistoryItem.chargeAmount {
            convenienceFeeDetailsLabel.text = "$\(String(describing: chargeAmount))"
        } else {
            convenienceFeeStackView.isHidden = true
            convenienceFeeSeparatorLine.isHidden = true
//            convenienceFeeDetailsLabel.text = "$0.00"
        }
        
        if let totalAmountDue = self.billingHistoryItem.totalAmountDue {
            totalAmountPaidDetailsLabel.text = "$\(String(describing: totalAmountDue))"
        } else {
            totalAmountPaidStackView.isHidden = true
            totalAmountPaidSeparatorLine.isHidden = true
//            totalAmountPaidDetailsLabel.text = "$0.00"
        }

        if self.billingHistoryItem.status != nil {
            paymentStatusDetailsLabel.text = self.billingHistoryItem.status
        } else {
            paymentStatusStackView.isHidden = true
            paymentAmountSeparatorLine.isHidden = true
        }
        
        if self.billingHistoryItem.confirmationNumber != nil {
            confirmationNumberDetailsLabel.text = self.billingHistoryItem.confirmationNumber
        } else {
            confirmationNumberStackView.isHidden = true
        }
        
        print(self.billingHistoryItem.paymentType ?? "Unknown")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
