//
//  PaperlessEBillAccountView.swift
//  Mobile
//
//  Created by Sam Francis on 4/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PaperlessEBillAccountView: UIView {
    
    @IBOutlet weak var checkbox: Checkbox!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var accountStackView: UIStackView!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!

    let bag = DisposeBag()

    var isChecked: ControlProperty<Bool>?

    override func awakeFromNib() {
        super.awakeFromNib()

        accountNumberLabel.textColor = .deepGray
        accountNumberLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        addressLabel.textColor = .deepGray
        addressLabel.font = SystemFont.regular.of(textStyle: .caption2)
    }

    static func create(withAccountDetail accountDetail: AccountDetail) -> PaperlessEBillAccountView {
        let view = Bundle.main.loadViewFromNib() as PaperlessEBillAccountView
        view.bind(withAccountDetail: accountDetail)
        return view
    }

    func bind(withAccountDetail accountDetail: AccountDetail) {
        let heightConstraint = heightAnchor.constraint(equalToConstant: 56)
        heightConstraint.priority = UILayoutPriority(rawValue: 999)
        heightConstraint.isActive = true

        accountNumberLabel.text = "\(accountDetail.accountNumber)"
        accountNumberLabel.accessibilityLabel = String(format: NSLocalizedString("Account number %@", comment: ""), accountDetail.accountNumber)
        if let address = accountDetail.address {
            addressLabel.text = address
            addressLabel.accessibilityLabel = String(format: NSLocalizedString("Street address %@", comment: ""), address)
        } else {
            addressLabel.text = ""
        }

        switch accountDetail.eBillEnrollStatus {
        case .canEnroll:
            checkbox.isEnabled = true
            checkbox.isChecked = false
            isChecked = checkbox.rx.isChecked
            
            imageView.image = accountDetail.isResidential ? #imageLiteral(resourceName: "ic_residential_mini") : #imageLiteral(resourceName: "ic_commercial_mini")
            accountNumberLabel.alpha = 1.0
            addressLabel.alpha = 1.0
        case .canUnenroll:
            checkbox.isEnabled = true
            checkbox.isChecked = true
            isChecked = checkbox.rx.isChecked
            
            imageView.image = accountDetail.isResidential ? #imageLiteral(resourceName: "ic_residential_mini") : #imageLiteral(resourceName: "ic_commercial_mini")
            accountNumberLabel.text = "\(accountNumberLabel.text!) (Enrolled)"
            accountNumberLabel.alpha = 1.0
            addressLabel.alpha = 1.0
        case .finaled:
            checkbox.isEnabled = false
            
            imageView.image = accountDetail.isResidential ? #imageLiteral(resourceName: "ic_residential_mini_disabled") : #imageLiteral(resourceName: "ic_commercial_mini_disabled")
            accountNumberLabel.text = "\(accountNumberLabel.text!) (Finaled)"
            accountNumberLabel.alpha = 0.4
            addressLabel.alpha = 0.4
            
        case .ineligible:
            checkbox.isEnabled = false
            
            imageView.image = accountDetail.isResidential ? #imageLiteral(resourceName: "ic_residential_mini_disabled") : #imageLiteral(resourceName: "ic_commercial_mini_disabled")
            accountNumberLabel.text = "\(accountNumberLabel.text!) (Ineligible)"
            accountNumberLabel.alpha = 0.4
            addressLabel.alpha = 0.4
        }

        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = NSLocalizedString("Residential account", comment: "")
        if let checkbox = checkbox {
            checkbox.isAccessibilityElement = true
            checkbox.accessibilityLabel = NSLocalizedString("Enrollment status: ",comment: "")
            self.accessibilityElements = [imageView, accountStackView, checkbox] as [UIView]
        } else {
            self.accessibilityElements = [imageView, accountStackView] as [UIView]
        }
    }

    func toggleCheckbox(checked: Bool) {
        guard let _ = isChecked else { return }
        checkbox.isChecked = checked
        checkbox.sendActions(for: .valueChanged)
    }

}
