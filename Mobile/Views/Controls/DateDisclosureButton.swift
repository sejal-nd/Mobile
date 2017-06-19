//
//  DateDisclosureButton.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class DateDisclosureButton: ButtonControl {

    @IBOutlet weak var dateDisclosureLabel: UILabel!
    @IBOutlet weak var selectedDateLabel: UILabel!

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 375, height: 44)
    }
    
    static func create(withLabel label: String) -> DateDisclosureButton {
        let view = Bundle.main.loadViewFromNib() as DateDisclosureButton
        
        view.bind(withLabel: label)
        
        return view
    }
    
    private func bind(withLabel label: String) {
        dateDisclosureLabel.text = label
        dateDisclosureLabel.font = SystemFont.regular.of(textStyle: .title2)
        
        selectedDateLabel.text = "mm/dd/yyyy"
    }

}
