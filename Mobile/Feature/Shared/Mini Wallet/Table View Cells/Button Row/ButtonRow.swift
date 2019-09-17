//
//  ButtonRow.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/26/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class ButtonRow: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var isEnabled = true {
        didSet {
            if isEnabled {
                iconImageView.alpha = 1.0
                titleLabel.alpha = 1.0
                
                selectionStyle = .default
                accessibilityTraits = .button
            } else {
                iconImageView.alpha = 0.4
                titleLabel.alpha = 0.4
                
                selectionStyle = .none
                accessibilityTraits = [.button, .notEnabled]
            }
        }
    }
    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        accessibilityTraits = .button
        style()
    }
    
    // MARK: - Helper
    
    private func style() {
        titleLabel.textColor = .deepGray
        titleLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        // Cell Selection Color
        let backgroundView = UIView()
        backgroundView.backgroundColor = .softGray
        selectedBackgroundView = backgroundView
    }
    
    func configure(image: UIImage?, title: String, isEnabled: Bool) {
        iconImageView.image = image
        titleLabel.text = title
        
        self.isEnabled = isEnabled

        accessibilityLabel = "\(iconImageView.accessibilityLabel ?? ""), \(titleLabel.accessibilityLabel ?? "")"
    }
}
