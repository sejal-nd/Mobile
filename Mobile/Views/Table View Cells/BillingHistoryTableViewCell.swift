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
                    self.amountLabel.text = item.amountPaid!.currencyString
                case "SCHEDULED": 
                    fallthrough
                default:
                    iconImageView.image = UIImage(named: "ic_scheduled")
                    titleLabel.text = SCHEDULED_PAYMENT
                    self.amountLabel.text = item.amountPaid!.currencyString
            }
        } else {
            switch item.description! {
                case "Regular Bill":
                    iconImageView.image = UIImage(named: "ic_bill")
                    titleLabel.text = BILL_ISSUED
                    self.amountLabel.text = item.totalAmountDue!.currencyString
                case "Late Payment Charge":
                    iconImageView.image = UIImage(named: "ic_alert")
                    titleLabel.text = LATE_PAYMENT
                    self.amountLabel.text = item.amountPaid!.currencyString
                case "Payment":
                    fallthrough
                default:
                    iconImageView.image = UIImage(named: "ic_paymentcheck")
                    titleLabel.text = PAYMENT
                    self.amountLabel.text = item.amountPaid!.currencyString
            }
        }
        
        dateLabel.text = item.date.mmDdYyyyString
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
