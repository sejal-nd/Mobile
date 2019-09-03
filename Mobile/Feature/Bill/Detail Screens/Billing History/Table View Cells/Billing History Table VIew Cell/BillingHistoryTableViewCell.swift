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
        
        titleLabel.textColor = .deepGray
        titleLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        dateLabel.textColor = .deepGray
        dateLabel.font = SystemFont.regular.of(textStyle: .caption1)
        amountLabel.textColor = .deepGray
        amountLabel.font = SystemFont.regular.of(textStyle: .subheadline)
    }

    func configureWith(item: BillingHistoryItem) {
        let dateString = item.date.shortMonthDayAndYearString
        dateLabel.text = item.date.mmDdYyyyString
                
        var a11y = ""
        if item.isBillPDF {
            iconImageView.image = #imageLiteral(resourceName: "ic_bill")
            let titleText = NSLocalizedString("Bill Issued", comment: "")
            titleLabel.text = titleText
            amountLabel.text = item.totalAmountDue?.currencyString
            a11y = String(format: NSLocalizedString("%@. %@. %@. View PDF", comment: ""), titleText, dateString, amountLabel.text ?? "")
        } else {
            guard let amountPaid = item.amountPaid?.currencyString else {
                return
            }
            amountLabel.text = amountPaid
            
            switch item.status {
            case .scheduled:
                let titleText = NSLocalizedString("Scheduled Payment", comment: "")
                iconImageView.image = #imageLiteral(resourceName: "ic_scheduled")
                titleLabel.text = titleText
                a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), titleText, dateString, amountPaid)
            case .pending:
                let titleText = NSLocalizedString("Pending Payment", comment: "")
                iconImageView.image = #imageLiteral(resourceName: "ic_pending")
                titleLabel.text = titleText
                dateLabel.isHidden = true
                a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), titleText, dateString, amountPaid)
            case .success, .unknown:
                let titleText = NSLocalizedString("Payment", comment: "")
                iconImageView.image = #imageLiteral(resourceName: "ic_activity_success")
                titleLabel.text = titleText
                amountLabel.textColor = .successGreenText
                amountLabel.font = SystemFont.semibold.of(textStyle: .subheadline)
                a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), titleText, dateString, amountPaid)
            case .failed:
                let titleText = NSLocalizedString("Failed Payment", comment: "")
                titleLabel.text = titleText
                iconImageView.image = #imageLiteral(resourceName: "ic_activity_failed")
                a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), titleText, dateString, amountPaid)
            case .canceled:
                let titleText = NSLocalizedString("Canceled Payment", comment: "")
                titleLabel.text = titleText
                iconImageView.image = #imageLiteral(resourceName: "ic_activity_canceled")
                a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), titleText, dateString, amountPaid)
            case .returned:
                let titleText = NSLocalizedString("Returned Payment", comment: "")
                titleLabel.text = titleText
                iconImageView.image = #imageLiteral(resourceName: "ic_activity_failed")
                a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), titleText, dateString, amountPaid)
            case .refunded:
                let titleText = NSLocalizedString("Refunded Payment", comment: "")
                titleLabel.text = titleText
                iconImageView.image = #imageLiteral(resourceName: "ic_activity_refunded")
                a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), titleText, dateString, amountPaid)
            }
        }
        innerContentView.accessibilityLabel = a11y
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dateLabel.text = ""
        titleLabel.text = ""
        amountLabel.textColor = .deepGray
        amountLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountLabel.text = ""
        iconImageView.image = nil
        dateLabel.isHidden = false
        disposeBag = DisposeBag()
    }
    
}
