//
//  TitleDetailRow.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/12/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class TitleSubTitleRow: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var disclosureIndicatorImageView: UIImageView!
    
    var isEnabled = true {
        didSet {
            if isEnabled {
                iconImageView.alpha = 1.0
                titleLabel.alpha = 1.0
                subTitleLabel.alpha = 1.0
                disclosureIndicatorImageView.alpha = 1.0
                
                selectionStyle = .default
            } else {
                iconImageView.alpha = 0.7
                titleLabel.alpha = 0.7
                subTitleLabel.alpha = 0.7
                disclosureIndicatorImageView.alpha = 0.7
                
                selectionStyle = .none
            }
        }
    }
    

    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        style()
    }
    
    
    // MARK: - Helper
    
    private func style() {
        titleLabel.textColor = .blackText
        titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        subTitleLabel.textColor = .middleGray
        subTitleLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        // Cell Selection Color
        let backgroundView = UIView()
        backgroundView.backgroundColor = .softGray
        selectedBackgroundView = backgroundView
    }
}


// MARK: - Cell Configuration

extension TitleSubTitleRow {
    func configure(image: UIImage? = nil, title: String, detail: String? = nil, disclosureIndicatorImage: UIImage? = UIImage(named: "ic_caret")) {
        iconImageView.image = image
        titleLabel.text = title
        subTitleLabel.text = detail
        disclosureIndicatorImageView.image = disclosureIndicatorImage
    }
    
    func updateSubTitle(_ text: String?) {
        subTitleLabel.text = text
    }
}
