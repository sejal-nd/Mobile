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
    @IBOutlet weak var enrollStatusLabel: UILabel!
    
    let bag = DisposeBag()
    
    var isOn: ControlProperty<Bool>?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        accountNumberLabel.font = SystemFont.medium.of(textStyle: .title1)
        addressLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        enrollStatusLabel.font = SystemFont.regular.of(textStyle: .subheadline)
    }
    
    static func create(withAccountDetail accountDetail: AccountDetail) -> PaperlessEBillAccountView {
        let view = Bundle.main.loadViewFromNib() as PaperlessEBillAccountView
        view.bind(withAccountDetail: accountDetail)
        return view
    }
    
    func bind(withAccountDetail accountDetail: AccountDetail) {
        let heightConstraint = heightAnchor.constraint(equalToConstant: 65)
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
            imageView.image = accountDetail.isResidential ? #imageLiteral(resourceName: "ic_residential") : #imageLiteral(resourceName: "ic_commercial")
            accountNumberLabel.textColor = .blackText
            addressLabel.textColor = .deepGray
            enrollStatusLabel.removeFromSuperview()
            enrollStatusLabel = nil
        case .canUnenroll:
            enrollSwitch.isOn = true
            isOn = enrollSwitch.rx.isOn
            imageView.image = accountDetail.isResidential ? #imageLiteral(resourceName: "ic_residential") : #imageLiteral(resourceName: "ic_commercial")
            accountNumberLabel.textColor = .blackText
            addressLabel.textColor = .deepGray
            enrollStatusLabel.removeFromSuperview()
            enrollStatusLabel = nil
        case .finaled:
            enrollStatusLabel.text = "Finaled"
            imageView.image = accountDetail.isResidential ? #imageLiteral(resourceName: "ic_residential_disabled") : #imageLiteral(resourceName: "ic_commercial_disabled")
            accountNumberLabel.textColor = .middleGray
            addressLabel.textColor = .middleGray
            enrollSwitch.removeFromSuperview()
            enrollSwitch = nil
        case .ineligible:
            enrollStatusLabel.text = "Ineligible"
            imageView.image = accountDetail.isResidential ? #imageLiteral(resourceName: "ic_residential_disabled") : #imageLiteral(resourceName: "ic_commercial_disabled")
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
            self.accessibilityElements = [imageView, accountStackView, enrollStatusLabel] as [UIView]
        }
    }
    
    func toggleSwitch(on: Bool) {
        guard let _ = isOn else { return }
        enrollSwitch.setOn(on, animated: true)
        enrollSwitch.sendActions(for: .valueChanged)
    }

}
