//
//  TotalSavingsTableViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 10/25/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class TotalSavingsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var testLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func bindToEvent(_ event: SERResult) {
        
    }

}
