//
//  BillingHistoryTableViewCell.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

enum BillingHistoryProperties: String {
    case TypeBilling = "billing"
    case TypePayment = "payment"
    case StatusCanceled = "canceled"
    case StatusCANCELLED = "CANCELLED" //PECO
    case StatusPosted = "Posted"
    case StatusFailed = "failed"
    case StatusPending = "Pending" //TODO: need to confirm case
    case StatusProcessing = "processing" //TODO: need to confirm case and existence
    case StatusScheduled = "scheduled"
    case StatusSCHEDULED = "SCHEDULED" //PECO
    case PaymentMethod_S = "S"
    case PaymentMethod_R = "R"
    case PaymentTypeSpeedpay = "SPEEDPAY"
    case PaymentTypeCSS = "CSS"
}

class BillingHistoryTableViewCell: UITableViewCell {
    
    let PAYMENT = NSLocalizedString("Payment", comment: "")
    let LATE_PAYMENT = NSLocalizedString("Late Payment Charge", comment: "")
    let PAYMENT_PROCESSING = NSLocalizedString("Payment Processing", comment: "")
    let SCHEDULED_PAYMENT = NSLocalizedString("Scheduled Payment", comment: "")
    let BILL_ISSUED = NSLocalizedString("Bill Issued", comment: "")
    let PENDING_PAYMENT = NSLocalizedString("Pending Payment", comment: "")

    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var amountLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dateLabel.text = ""
        titleLabel.text = ""
        amountLabel.text = ""
        amountLabel.textColor = UIColor.black
        iconImageView.image = nil
    }
    
    func configureWith(item: BillingHistoryItem) {
        
        if item.isFuture {
            configureUpcomingCell(item: item)
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
    
    private func configureUpcomingCell(item: BillingHistoryItem) {
        guard let status = item.status,
            let amountPaid = item.amountPaid?.currencyString else { return }
        
        if status == BillingHistoryProperties.StatusPending.rawValue {
            iconImageView.image = #imageLiteral(resourceName: "ic_scheduled")
            titleLabel.text = PENDING_PAYMENT
            self.amountLabel.text = amountPaid
        } else if status == BillingHistoryProperties.StatusProcessing.rawValue {
            iconImageView.image = #imageLiteral(resourceName: "ic_pending")
            titleLabel.text = PAYMENT_PROCESSING
            self.amountLabel.text = amountPaid
            dateLabel.isHidden = true
        } else if status == BillingHistoryProperties.StatusCanceled.rawValue || 
            status == BillingHistoryProperties.StatusCANCELLED.rawValue ||
            status == BillingHistoryProperties.StatusFailed.rawValue {
            iconImageView.image = #imageLiteral(resourceName: "ic_paymentcanceledfailed")
            titleLabel.text = PAYMENT
            amountLabel.text = amountPaid
        } else { //status = scheduled?  hopefully
            iconImageView.image = #imageLiteral(resourceName: "ic_pending")
            titleLabel.text = SCHEDULED_PAYMENT
            self.amountLabel.text = amountPaid
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
