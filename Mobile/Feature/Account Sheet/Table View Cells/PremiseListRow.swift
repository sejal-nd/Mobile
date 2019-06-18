//
//  PremiseListRow.swift
//  Mobile
//
//  Created by Joseph Erlandson on 6/17/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class PremiseListRow: UITableViewCell {
    
    @IBOutlet weak var checkMarkImageView: UIImageView!
    @IBOutlet weak var accountNumber: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        accountNumber.textColor = .blackText
        accountNumber.font = SystemFont.regular.of(textStyle: .headline)
    }
    
}


// MARK: - Cell Configuration

extension PremiseListRow {
    func configureWithPremise(_ premise: Premise) {
        accountNumber.text = premise.premiseNumber
    }
}
