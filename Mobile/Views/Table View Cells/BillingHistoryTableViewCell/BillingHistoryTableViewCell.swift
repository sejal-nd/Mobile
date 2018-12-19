//
//  BillingHistoryTableViewCell.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BillingHistoryTableViewCell: UITableViewCell {
    
    let PAYMENT = NSLocalizedString("Payment", comment: "")
    let LATE_PAYMENT = NSLocalizedString("Late Payment Charge", comment: "")
    let PAYMENT_PROCESSING = NSLocalizedString("Payment Processing", comment: "")
    let SCHEDULED_PAYMENT = NSLocalizedString("Scheduled Payment", comment: "")
    let BILL_ISSUED = NSLocalizedString("Bill Issued", comment: "")
    let PENDING_PAYMENT = NSLocalizedString("Pending Payment", comment: "")

    @IBOutlet weak var innerContentView: ButtonControl!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var caretImageView: UIImageView!
    
    var disposeBag = DisposeBag()
    
    private(set) lazy var didSelect: Driver<Void> = self.innerContentView.rx.touchUpInside.asDriver()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        titleLabel.textColor = .blackText
        titleLabel.font = SystemFont.medium.of(textStyle: .headline)
        dateLabel.textColor = .deepGray
        dateLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountLabel.font = SystemFont.semibold.of(textStyle: .headline)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dateLabel.text = ""
        titleLabel.text = ""
        amountLabel.text = ""
        amountLabel.textColor = .blackText
        iconImageView.image = nil
        caretImageView.isHidden = false
        dateLabel.isHidden = false
        disposeBag = DisposeBag()
    }
    
    func configureWith(item: BillingHistoryItem) {
        dateLabel.text = item.date.mmDdYyyyString
        if item.isFuture {
            configureUpcomingCell(item: item)
        } else {
            configurePastCell(item: item)
        }
    }
    
    private func configurePastCell(item: BillingHistoryItem) {
        let dateString = item.date.shortMonthDayAndYearString
        
        var a11y = ""
        if item.isBillPDF {
            iconImageView.image = #imageLiteral(resourceName: "ic_bill")
            titleLabel.text = BILL_ISSUED
            amountLabel.text = item.totalAmountDue?.currencyString
            a11y = String(format: NSLocalizedString("%@. %@. %@. View PDF", comment: ""), BILL_ISSUED, dateString, amountLabel.text ?? "")
        } else {
            guard let amountPaid = item.amountPaid?.currencyString else {
                return
            }
            
            let status = item.status
            if status == .canceled || status == .failed {
                titleLabel.text = PAYMENT
                amountLabel.text = amountPaid
                if status == .failed {
                    iconImageView.image = #imageLiteral(resourceName: "ic_activity_failed")
                    a11y = String(format: NSLocalizedString("Failed %@. %@. %@.", comment: ""), PAYMENT, dateString, amountLabel.text ?? "")
                } else {
                    iconImageView.image = #imageLiteral(resourceName: "ic_activity_canceled")
                    a11y = String(format: NSLocalizedString("Cancelled %@. %@. %@.", comment: ""), PAYMENT, dateString, amountLabel.text ?? "")
                }
            } else if status == .scheduled {
                iconImageView.image = #imageLiteral(resourceName: "ic_scheduled")
                titleLabel.text = SCHEDULED_PAYMENT
                self.amountLabel.text = amountPaid
                a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), SCHEDULED_PAYMENT, dateString, amountPaid)
            } else {
                iconImageView.image = #imageLiteral(resourceName: "ic_activity_success")
                titleLabel.text = PAYMENT
                amountLabel.text = "\(String(describing: amountPaid))"
                amountLabel.textColor = .successGreenText
                a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), PAYMENT, dateString, amountLabel.text ?? "")
            }
        }
        innerContentView.accessibilityLabel = a11y
    }
    
    private func configureUpcomingCell(item: BillingHistoryItem) {
        guard let amountPaid = item.amountPaid?.currencyString else { return }
        
        var a11y = ""
        let dateString = item.date.shortMonthDayAndYearString
        
        let status = item.status
        if status == .pending {
            iconImageView.image = #imageLiteral(resourceName: "ic_pending")
            titleLabel.text = PENDING_PAYMENT
            amountLabel.text = amountPaid
            dateLabel.isHidden = true
            caretImageView.isHidden = true
            a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), PENDING_PAYMENT, dateString, amountPaid)
        } else if status == .processing || status == .processed {
            iconImageView.image = #imageLiteral(resourceName: "ic_pending")
            titleLabel.text = PAYMENT_PROCESSING
            amountLabel.text = amountPaid
            dateLabel.isHidden = true
            caretImageView.isHidden = false
            a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), PAYMENT_PROCESSING, dateString, amountPaid)
        } else if status == .canceled || status == .failed {
            titleLabel.text = PAYMENT
            amountLabel.text = amountPaid
            caretImageView.isHidden = false
            if status == .failed {
                iconImageView.image = #imageLiteral(resourceName: "ic_activity_failed")
                a11y = String(format: NSLocalizedString("Failed %@. %@. %@.", comment: ""), PAYMENT, dateString, amountPaid)
            } else {
                iconImageView.image = #imageLiteral(resourceName: "ic_activity_canceled")
                a11y = String(format: NSLocalizedString("Cancelled %@. %@. %@.", comment: ""), PAYMENT, dateString, amountPaid)
            }
        } else {
            iconImageView.image = #imageLiteral(resourceName: "ic_scheduled")
            titleLabel.text = SCHEDULED_PAYMENT
            amountLabel.text = amountPaid
            caretImageView.isHidden = false
            a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), SCHEDULED_PAYMENT, dateString, amountPaid)
        }
        innerContentView.accessibilityLabel = a11y
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
