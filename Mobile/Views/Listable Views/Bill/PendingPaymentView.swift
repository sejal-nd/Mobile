//
//  PendingPaymentView.swift
//  Mobile
//
//  Created by Sam Francis on 5/8/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class PendingPaymentView: UIView {
    
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 303, height: 51)
    }
    
    static func create(withAmount amount: Double) -> PendingPaymentView {
        let view = Bundle.main.loadViewFromNib() as PendingPaymentView
        view.bind(withAmount: amount)
        return view
    }
    
    private func bind(withAmount amount: Double) {
        switch Environment.shared.opco {
        case .bge:
            textLabel.text = NSLocalizedString("Payment Processing", comment: "")
        case .comEd, .peco:
            textLabel.text = NSLocalizedString("Pending Payment", comment: "")
        }
		
		textLabel.font = OpenSans.italic.of(textStyle: .subheadline)
        amountLabel.text = "-\(amount.currencyString)" // EM1-1802: Show pending/received/processing payments as negative
        amountLabel.font = OpenSans.semiboldItalic.of(textStyle: .headline)
    }

}
