//
//  BillingHistoryTableViewCell.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class BillingHistoryTableViewCell: UITableViewCell {
    
    let PAYMENT = "Payment"
    let LATE_PAYMENT = "Late Payment Charge"
    let PAYMENT_PROCESSING = "Payment Processing"
    let SCHEDULED_PAYMENT = "Scheduled Payment"
    let BILL_ISSUED = "Bill Issued"
    
    enum BillingHistoryProperties: String {
        case TypeBilling = "billing"
        case TypePayment = "payment"
        case StatusCanceled = "canceled"
        case StatusCANCELLED = "CANCELLED" //PECO
        case StatusPosted = "Posted"
        case StatusFailed = "failed"
    }

    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var amountLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureWith(item: BillingHistoryItem) {
        
        if item.isFuture {
            switch item.status! {
                case "PROCESSING":
                    iconImageView.image = UIImage(named: "ic_pending")
                    titleLabel.text = PAYMENT_PROCESSING
                    self.amountLabel.text = item.amountPaid?.currencyString
                case "SCHEDULED": 
                    fallthrough
                default:
                    iconImageView.image = UIImage(named: "ic_scheduled")
                    titleLabel.text = SCHEDULED_PAYMENT
                    self.amountLabel.text = item.amountPaid?.currencyString
            }
        } else {
            configurePastCell(item: item)
        }
        
        dateLabel.text = item.date.mmDdYyyyString
    }
    
    private func configurePastCell(item: BillingHistoryItem) {
        if item.type == BillingHistoryProperties.TypeBilling.rawValue {
            iconImageView.image = #imageLiteral(resourceName: "ic_bill")
            titleLabel.text = BILL_ISSUED
            amountLabel.text = item.totalAmountDue?.currencyString
        } else {
            guard let status = item.status,
                let amountPaid = item.amountPaid?.currencyString else { return }
            if status == BillingHistoryProperties.StatusCanceled.rawValue || 
                status == BillingHistoryProperties.StatusCANCELLED.rawValue ||
                status == BillingHistoryProperties.StatusFailed.rawValue {
                    iconImageView.image = #imageLiteral(resourceName: "ic_paymentcanceledfailed")
                    titleLabel.text = PAYMENT
                    amountLabel.text = amountPaid
            } else {
                iconImageView.image = #imageLiteral(resourceName: "ic_paymentcheck")
                titleLabel.text = PAYMENT
                amountLabel.text = "-\(String(describing: amountPaid))"
                amountLabel.textColor = .successGreenText
            }
        }
    }
    
    class var identifier: String{
        struct Static
        {
            static let identifier: String = "BillingHistoryTableViewCell"
        }
        
        return Static.identifier
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
