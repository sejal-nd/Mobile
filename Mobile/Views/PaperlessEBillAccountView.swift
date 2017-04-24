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

enum EBillEnrollStatus {
    case canEnroll, finaled, ineligible
}

class PaperlessEBillAccountView: UIView {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var enrollSwitch: Switch!
    @IBOutlet weak var enrollStatusLabel: UILabel!
    
    let bag = DisposeBag()
    
    var isOn = Driver<Bool>.empty()
    
    static func create(withAccount account: Account, enrollStatus: EBillEnrollStatus) -> PaperlessEBillAccountView {
        let view = Bundle.main.loadNibNamed("PaperlessEBillAccountView", owner: nil, options: nil)![0] as! PaperlessEBillAccountView
        
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 65)
        heightConstraint.priority = 999
        heightConstraint.isActive = true
        
        switch enrollStatus {
        case .canEnroll:
            view.isOn = view.enrollSwitch.rx.isOn.asDriver()
            view.imageView.image = #imageLiteral(resourceName: "ic_residential")
            view.enrollStatusLabel.removeFromSuperview()
            view.enrollStatusLabel = nil
        case .finaled:
            view.enrollStatusLabel.text = "Finaled"
            view.imageView.image = #imageLiteral(resourceName: "ic_residential_disabled")
            view.enrollSwitch.removeFromSuperview()
            view.enrollSwitch = nil
        case .ineligible:
            view.enrollStatusLabel.text = "Ineligible"
            view.imageView.image = #imageLiteral(resourceName: "ic_residential_disabled")
            view.enrollSwitch.removeFromSuperview()
            view.enrollSwitch = nil
        }
        
        return view
    }

}
