//
//  DateDisclosureButton.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class DateDisclosureButton: ButtonControl {
    
    let selectedDateText = NSLocalizedString("Select Date", comment: "")

    @IBOutlet weak var dateDisclosureLabel: UILabel!
    @IBOutlet weak var selectedDateLabel: UILabel!

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 375, height: 60)
    }
    
    static func create(withLabel label: String) -> DateDisclosureButton {
        let view = Bundle.main.loadViewFromNib() as DateDisclosureButton
        
        view.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 6)
        
        view.bind(withLabel: label)
        
        return view
    }
    
    private func bind(withLabel label: String) {
        dateDisclosureLabel.text = label
        dateDisclosureLabel.font = SystemFont.regular.of(textStyle: .title2)
        
        selectedDateLabel.text = selectedDateText
        
    }
    
    func accessibilityUpdate(dateText: String) {
        isAccessibilityElement = true
        let localizedText = NSLocalizedString("%@: $@", comment: "")
        accessibilityLabel = String(format: localizedText, selectedDateText, dateText)
    }

}
