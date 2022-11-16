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
        
        savingsDayLabel.textColor = .neutralDark
        savingsDayLabel.font = .subheadline
        
        billCreditLabel.textColor = .neutralDark
        billCreditLabel.font = .subheadlineSemibold
        
        typicalUseLabel.textColor = .neutralDark
        typicalUseLabel.font = .subheadline
        
        actualUseLabel.textColor = .neutralDark
        actualUseLabel.font = .subheadline
        
        energySavingsLabel.textColor = .neutralDark
        energySavingsLabel.font = .subheadline
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
        
        savingsDayLabel.textColor = .neutralDark
        savingsDayLabel.font = .caption1Semibold
        savingsDayLabel.text = NSLocalizedString("Savings Day", comment: "")
        
        billCreditLabel.textColor = .neutralDark
        billCreditLabel.font = .caption1Semibold
        billCreditLabel.text = NSLocalizedString("Bill Credit", comment: "")
        
        typicalUseLabel.textColor = .neutralDark
        typicalUseLabel.font = .caption1Semibold
        typicalUseLabel.text = NSLocalizedString("Typical Use", comment: "")
        
        actualUseLabel.textColor = .neutralDark
        actualUseLabel.font = .caption1Semibold
        actualUseLabel.text = NSLocalizedString("Actual Use", comment: "")
        
        energySavingsLabel.textColor = .neutralDark
        energySavingsLabel.font = .caption1Semibold
        energySavingsLabel.text = NSLocalizedString("Energy Savings", comment: "")
    }

}

