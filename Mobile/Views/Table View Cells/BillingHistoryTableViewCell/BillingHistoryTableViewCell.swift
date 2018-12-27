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
        
        titleLabel.textColor = .blackText
        titleLabel.font = SystemFont.medium.of(textStyle: .headline)
        dateLabel.textColor = .deepGray
        dateLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountLabel.font = SystemFont.semibold.of(textStyle: .headline)
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
            let titleText = NSLocalizedString("Bill Issued", comment: "")
            titleLabel.text = titleText
            amountLabel.text = item.totalAmountDue?.currencyString
            a11y = String(format: NSLocalizedString("%@. %@. %@. View PDF", comment: ""), titleText, dateString, amountLabel.text ?? "")
        } else {
            guard let amountPaid = item.amountPaid?.currencyString else {
                return
            }
            
            switch item.status {
            case .scheduled:
                let titleText = NSLocalizedString("Scheduled Payment", comment: "")
                iconImageView.image = #imageLiteral(resourceName: "ic_scheduled")
                titleLabel.text = titleText
                amountLabel.text = amountPaid
                a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), titleText, dateString, amountPaid)
            case .canceled:
                let titleText = NSLocalizedString("Payment", comment: "")
                titleLabel.text = titleText
                amountLabel.text = amountPaid
                iconImageView.image = #imageLiteral(resourceName: "ic_activity_canceled")
                a11y = String(format: NSLocalizedString("Canceled %@. %@. %@.", comment: ""), titleText, dateString, amountLabel.text ?? "")
            case .failed:
                let titleText = NSLocalizedString("Payment", comment: "")
                titleLabel.text = titleText
                amountLabel.text = amountPaid
                iconImageView.image = #imageLiteral(resourceName: "ic_activity_failed")
                a11y = String(format: NSLocalizedString("Failed %@. %@. %@.", comment: ""), titleText, dateString, amountLabel.text ?? "")
            default:
                let titleText = NSLocalizedString("Payment", comment: "")
                iconImageView.image = #imageLiteral(resourceName: "ic_activity_success")
                titleLabel.text = titleText
                amountLabel.text = amountPaid
                amountLabel.textColor = .successGreenText
                a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), titleText, dateString, amountLabel.text ?? "")
            }
        }
        innerContentView.accessibilityLabel = a11y
    }
    
    private func configureUpcomingCell(item: BillingHistoryItem) {
        guard let amountPaid = item.amountPaid?.currencyString else { return }
        
        var a11y = ""
        let dateString = item.date.shortMonthDayAndYearString
        
        switch item.status {
        case .pending:
            iconImageView.image = #imageLiteral(resourceName: "ic_pending")
            let titleText = NSLocalizedString("Pending Payment", comment: "")
            titleLabel.text = titleText
            amountLabel.text = amountPaid
            dateLabel.isHidden = true
            caretImageView.isHidden = true
            innerContentView.isUserInteractionEnabled = false
            a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), titleText, dateString, amountPaid)
        case .processing, .processed:
            iconImageView.image = #imageLiteral(resourceName: "ic_pending")
            let titleText = NSLocalizedString("Payment Processing", comment: "")
            titleLabel.text = titleText
            amountLabel.text = amountPaid
            dateLabel.isHidden = true
            caretImageView.isHidden = false
            innerContentView.isUserInteractionEnabled = true
            a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), titleText, dateString, amountPaid)
        case .canceled:
            let titleText = NSLocalizedString("Payment", comment: "")
            titleLabel.text = titleText
            amountLabel.text = amountPaid
            caretImageView.isHidden = false
            iconImageView.image = #imageLiteral(resourceName: "ic_activity_canceled")
            innerContentView.isUserInteractionEnabled = true
            a11y = String(format: NSLocalizedString("Canceled %@. %@. %@.", comment: ""), titleText, dateString, amountPaid)
        case .failed:
            let titleText = NSLocalizedString("Payment", comment: "")
            titleLabel.text = titleText
            amountLabel.text = amountPaid
            caretImageView.isHidden = false
            iconImageView.image = #imageLiteral(resourceName: "ic_activity_failed")
            innerContentView.isUserInteractionEnabled = true
            a11y = String(format: NSLocalizedString("Failed %@. %@. %@.", comment: ""), titleText, dateString, amountPaid)
        default:
            let titleText = NSLocalizedString("Scheduled Payment", comment: "")
            iconImageView.image = #imageLiteral(resourceName: "ic_scheduled")
            titleLabel.text = titleText
            amountLabel.text = amountPaid
            caretImageView.isHidden = false
            innerContentView.isUserInteractionEnabled = true
            a11y = String(format: NSLocalizedString("%@. %@. %@.", comment: ""), titleText, dateString, amountPaid)
        }
        
        innerContentView.accessibilityLabel = a11y
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
    
}
