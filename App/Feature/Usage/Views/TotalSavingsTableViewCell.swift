//
//  TotalSavingsTableViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 10/25/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class TotalSavingsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var savingsDayLabel: UILabel!
    @IBOutlet weak var billCreditLabel: UILabel!
    @IBOutlet weak var typicalUseLabel: UILabel!
    @IBOutlet weak var actualUseLabel: UILabel!
    @IBOutlet weak var energySavingsLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        savingsDayLabel.textColor = .deepGray
        savingsDayLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        billCreditLabel.textColor = .deepGray
        billCreditLabel.font = SystemFont.semibold.of(textStyle: .subheadline)
        
        typicalUseLabel.textColor = .deepGray
        typicalUseLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        actualUseLabel.textColor = .deepGray
        actualUseLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        energySavingsLabel.textColor = .deepGray
        energySavingsLabel.font = SystemFont.regular.of(textStyle: .subheadline)
    }

    func bindToEvent(_ event: SERResult) {
        savingsDayLabel.text = event.eventStart.mmDdYyyyString
        billCreditLabel.text = event.savingDollar.currencyString
        typicalUseLabel.text = String(format: "%.1f kWh", event.baselineKWH)
        actualUseLabel.text = String(format: "%.1f kWh", event.actualKWH)
        energySavingsLabel.text = String(format: "%.1f kWh", event.savingKWH)
        
        accessibilityLabel = String(format: "%@: %@, %@: %@, %@: %@, %@: %@, %@: %@",
            NSLocalizedString("Savings Day", comment: ""),
            savingsDayLabel.text!,
            NSLocalizedString("Bill Credit", comment: ""),
            billCreditLabel.text!,
            NSLocalizedString("Typical Use", comment: ""),
            typicalUseLabel.text!,
            NSLocalizedString("Actual Use", comment: ""),
            actualUseLabel.text!,
            NSLocalizedString("Energy Savings", comment: ""),
            energySavingsLabel.text!
        )
    }

}

class TotalSavingsHeaderCell: UITableViewCell {
    
    @IBOutlet weak var savingsDayLabel: UILabel!
    @IBOutlet weak var billCreditLabel: UILabel!
    @IBOutlet weak var typicalUseLabel: UILabel!
    @IBOutlet weak var actualUseLabel: UILabel!
    @IBOutlet weak var energySavingsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        accessibilityElementsHidden = true // Disable a11y on header cell
        
        savingsDayLabel.textColor = .deepGray
        savingsDayLabel.font = SystemFont.semibold.of(textStyle: .caption1)
        savingsDayLabel.text = NSLocalizedString("Savings Day", comment: "")
        
        billCreditLabel.textColor = .deepGray
        billCreditLabel.font = SystemFont.semibold.of(textStyle: .caption1)
        billCreditLabel.text = NSLocalizedString("Bill Credit", comment: "")
        
        typicalUseLabel.textColor = .deepGray
        typicalUseLabel.font = SystemFont.semibold.of(textStyle: .caption1)
        typicalUseLabel.text = NSLocalizedString("Typical Use", comment: "")
        
        actualUseLabel.textColor = .deepGray
        actualUseLabel.font = SystemFont.semibold.of(textStyle: .caption1)
        actualUseLabel.text = NSLocalizedString("Actual Use", comment: "")
        
        energySavingsLabel.textColor = .deepGray
        energySavingsLabel.font = SystemFont.semibold.of(textStyle: .caption1)
        energySavingsLabel.text = NSLocalizedString("Energy Savings", comment: "")
    }

}

