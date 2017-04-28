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
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var enrollSwitch: Switch!
    @IBOutlet weak var enrollStatusLabel: UILabel!
    
    let bag = DisposeBag()
    
    var isOn: ControlProperty<Bool>?
    
    static func create(withAccountDetail accountDetail: AccountDetail) -> PaperlessEBillAccountView {
        let view = Bundle.main.loadNibNamed("PaperlessEBillAccountView", owner: nil, options: nil)![0] as! PaperlessEBillAccountView
        view.bind(withAccountDetail: accountDetail)
        return view
    }
    
    func bind(withAccountDetail accountDetail: AccountDetail) {
        let heightConstraint = heightAnchor.constraint(equalToConstant: 65)
        heightConstraint.priority = 999
        heightConstraint.isActive = true
        
        accountNumberLabel.text = "\(accountDetail.accountNumber)"
        addressLabel.text = accountDetail.address
        
        switch accountDetail.eBillEnrollStatus {
        case .canEnroll:
            enrollSwitch.isOn = false
            isOn = enrollSwitch.rx.isOn
            imageView.image = #imageLiteral(resourceName: "ic_residential")
            accountNumberLabel.textColor = .darkJungleGreen
            addressLabel.textColor = .trolleyGrey
            enrollStatusLabel.removeFromSuperview()
            enrollStatusLabel = nil
        case .canUnenroll:
            enrollSwitch.isOn = true
            isOn = enrollSwitch.rx.isOn
            imageView.image = #imageLiteral(resourceName: "ic_residential")
            accountNumberLabel.textColor = .darkJungleGreen
            addressLabel.textColor = .trolleyGrey
            enrollStatusLabel.removeFromSuperview()
            enrollStatusLabel = nil
        case .finaled:
            enrollStatusLabel.text = "Finaled"
            imageView.image = #imageLiteral(resourceName: "ic_residential_disabled")
            accountNumberLabel.textColor = .oldLavender
            addressLabel.textColor = .oldLavender
            enrollSwitch.removeFromSuperview()
            enrollSwitch = nil
        case .ineligible:
            enrollStatusLabel.text = "Ineligible"
            imageView.image = #imageLiteral(resourceName: "ic_residential_disabled")
            accountNumberLabel.textColor = .oldLavender
            addressLabel.textColor = .oldLavender
            enrollSwitch.removeFromSuperview()
            enrollSwitch = nil
        }
    }
    
    func toggleSwitch(on: Bool) {
        enrollSwitch.setOn(on, animated: true)
        enrollSwitch.sendActions(for: .valueChanged)
    }

}
