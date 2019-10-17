//
//  AlertRow.swift
//  Mobile
//
//  Created by Joseph Erlandson on 8/26/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class AlertRow: UITableViewCell {
    @IBOutlet weak var textView: UITextView!
    
    
    // Mark: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textView.textColor = .deepGray
        textView.font = SystemFont.regular.of(textStyle: .subheadline)
    }
    
    
    // Mark: - Config
    
    func configure(with text: String?) {
        textView.text = text
    }
}
