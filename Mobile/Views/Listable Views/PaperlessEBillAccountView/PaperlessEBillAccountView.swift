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
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var accountStackView: UIStackView!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var enrollSwitch: Switch!

    let bag = DisposeBag()

    var isOn: ControlProperty<Bool>?

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
            enrollSwitch.isOn = false
            isOn = enrollSwitch.rx.isOn
            imageView.image = accountDetail.isResidential ? #imageLiteral(resourceName: "ic_residential_mini") : #imageLiteral(resourceName: "ic_commercial_mini")
            accountNumberLabel.textColor = .blackText
            addressLabel.textColor = .deepGray
        case .canUnenroll:
            accountNumberLabel.text = "\(accountNumberLabel.text!) (Enrolled)"
            enrollSwitch.isOn = true
            isOn = enrollSwitch.rx.isOn
            imageView.image = accountDetail.isResidential ? #imageLiteral(resourceName: "ic_residential_mini") : #imageLiteral(resourceName: "ic_commercial_mini")
            accountNumberLabel.textColor = .blackText
            addressLabel.textColor = .deepGray
        case .finaled:
            accountNumberLabel.text = "\(accountNumberLabel.text!) (Finaled)"
            imageView.image = accountDetail.isResidential ? #imageLiteral(resourceName: "ic_residential_mini_disabled") : #imageLiteral(resourceName: "ic_commercial_mini_disabled")
            accountNumberLabel.textColor = .middleGray
            addressLabel.textColor = .middleGray
            enrollSwitch.removeFromSuperview()
            enrollSwitch = nil
        case .ineligible:
            accountNumberLabel.text = "\(accountNumberLabel.text!) (Ineligible)"
            imageView.image = accountDetail.isResidential ? #imageLiteral(resourceName: "ic_residential_mini_disabled") : #imageLiteral(resourceName: "ic_commercial_mini_disabled")
            accountNumberLabel.textColor = .middleGray
            addressLabel.textColor = .middleGray
            enrollSwitch.removeFromSuperview()
            enrollSwitch = nil
        }

        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = NSLocalizedString("Residential account", comment: "")
        if let enrollSwitch = enrollSwitch {
            enrollSwitch.isAccessibilityElement = true
            enrollSwitch.accessibilityLabel = NSLocalizedString("Enrollment status: ",comment: "")
            self.accessibilityElements = [imageView, accountStackView, enrollSwitch] as [UIView]
        } else {
            self.accessibilityElements = [imageView, accountStackView] as [UIView]
        }
    }

    func toggleSwitch(on: Bool) {
        guard let _ = isOn else { return }
        enrollSwitch.setOn(on, animated: true)
        enrollSwitch.sendActions(for: .valueChanged)
    }

}
