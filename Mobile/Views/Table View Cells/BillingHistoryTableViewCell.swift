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
    
    //TODO: this is not complete - just trying to get something working so I can test
    //the webservices
    func configureWith(amount: String, date: String, isFuture: Bool) {
        self.amountLabel.text = amount
        self.dateLabel.text = date
        
        if isFuture {
            iconImageView.image = UIImage(named: "ic_scheduled")
            titleLabel.text = SCHEDULED_PAYMENT
        } else {
            iconImageView.image = UIImage(named: "ic_bill")
            titleLabel.text = BILL_ISSUED
        }
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
