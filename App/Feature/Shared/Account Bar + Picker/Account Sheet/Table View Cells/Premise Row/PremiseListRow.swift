//
//  PremiseListRow.swift
//  Mobile
//
//  Created by Joseph Erlandson on 6/17/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class PremiseListRow: UITableViewCell {
    
    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var accountNumber: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        accountNumber.textColor = .blackText
        accountNumber.font = .headline
    }
    
}


// MARK: - Cell Configuration

extension PremiseListRow {
    func configureWithPremise(_ premise: PremiseInfo, indexPath: IndexPath, selectedIndexPath: IndexPath?) {
        accountNumber.text = premise.addressLineString
        
        var a11yString = ""
        
        if let selectedIndexPath = selectedIndexPath, indexPath == selectedIndexPath {
            checkmarkImageView.isHidden = false
            a11yString += "Selected,"
        } else {
            checkmarkImageView.isHidden = true
        }
        
        // Cell Selection Color
        let backgroundView = UIView()
        backgroundView.backgroundColor = .softGray
        selectedBackgroundView = backgroundView
        
        // Accessibility
        self.accessibilityLabel = "\(a11yString)Premise \(accountNumber.text ?? "")"
    }
}
